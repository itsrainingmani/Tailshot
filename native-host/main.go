package main

import (
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Constants
const (
	LogFileName      = "debug.log"
	TempFilePattern  = "tailscale-sender-*"
	DataURLSeparator = ","
)

// Message represents the structure of messages between extension and host
type Message struct {
	Action     string `json:"action"`
	DeviceName string `json:"device_name,omitempty"`
	ImageData  string `json:"image_data,omitempty"`
	FileName   string `json:"file_name,omitempty"`
	ImageType  string `json:"image_type,omitempty"`
}

// Response represents the response structure
type Response struct {
	Success bool   `json:"success"`
	Data    any    `json:"data,omitempty"`
	Error   string `json:"error,omitempty"`
}

// Device represents a Tailscale device
type Device struct {
	Name   string `json:"name"`
	ID     string `json:"id"`
	Online bool   `json:"online"`
	OS     string `json:"os"`
}

type TaildropTargetStatus int

const (
	TaildropTargetUnknown TaildropTargetStatus = iota
	TaildropTargetAvailable
	TaildropTargetNoNetmapAvailable
	TaildropTargetIpnStateNotRunning
	TaildropTargetMissingCap
	TaildropTargetOffline
	TaildropTargetNoPeerInfo
	TaildropTargetUnsupportedOS
	TaildropTargetNoPeerAPI
	TaildropTargetOwnedByOtherUser
)

// TailscaleStatus represents the structure of tailscale status --json
type TailscaleStatus struct {
	Peer map[string]TailscalePeer `json:"Peer"`
}

// TailscalePeer represents a peer in Tailscale status
type TailscalePeer struct {
	ID             string               `json:"ID"`
	HostName       string               `json:"HostName"`
	DNSName        string               `json:"DNSName"` // eg: fetch.llama-byzantine.ts.net
	OS             string               `json:"OS"`
	Online         bool                 `json:"Online"`
	ExitNodeOption bool                 `json:"ExitNodeOption"`
	TaildropTarget TaildropTargetStatus `json:"TaildropTarget"`
}

// NativeHost handles native messaging operations
type NativeHost struct {
	logger *log.Logger
}

// NewNativeHost creates a new native host instance
func NewNativeHost() (*NativeHost, error) {
	logFile, err := os.OpenFile(LogFileName, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %w", err)
	}

	logger := log.New(logFile, "", log.LstdFlags|log.Lshortfile)

	// Ensure log file is closed when process exits
	go func() {
		defer logFile.Close()
	}()

	return &NativeHost{logger: logger}, nil
}

// logError logs an error and sends it as response
func (nh *NativeHost) logError(msg string, err error) {
	fullMsg := fmt.Sprintf("%s: %v", msg, err)
	nh.logger.Printf("ERROR: %s", fullMsg)
	nh.sendMessage(Response{Success: false, Error: fullMsg})
}

// sendMessage sends a message back to the extension
func (nh *NativeHost) sendMessage(response Response) {
	jsonData, err := json.Marshal(response)
	if err != nil {
		nh.logger.Printf("ERROR: Failed to marshal response: %v", err)
		return
	}

	// Write length prefix
	length := uint32(len(jsonData))
	if err := binary.Write(os.Stdout, binary.LittleEndian, length); err != nil {
		nh.logger.Printf("ERROR: Failed to write length: %v", err)
		return
	}

	// Write JSON data
	if _, err := os.Stdout.Write(jsonData); err != nil {
		nh.logger.Printf("ERROR: Failed to write data: %v", err)
		return
	}

	if err := os.Stdout.Sync(); err != nil {
		nh.logger.Printf("ERROR: Failed to sync stdout: %v", err)
		return
	}

	nh.logger.Printf("Response sent: success=%v", response.Success)
}

// readMessage reads a message from the extension
func (nh *NativeHost) readMessage() (*Message, error) {
	// Read length prefix
	var length uint32
	if err := binary.Read(os.Stdin, binary.LittleEndian, &length); err != nil {
		if err == io.EOF {
			nh.logger.Printf("Connection closed by extension")
			os.Exit(0)
		}
		return nil, fmt.Errorf("failed to read length: %w", err)
	}

	// Read message data
	messageData := make([]byte, length)
	if _, err := io.ReadFull(os.Stdin, messageData); err != nil {
		return nil, fmt.Errorf("failed to read message data: %w", err)
	}

	// Parse JSON
	var message Message
	if err := json.Unmarshal(messageData, &message); err != nil {
		return nil, fmt.Errorf("failed to unmarshal JSON: %w", err)
	}

	nh.logger.Printf("Received action: %s", message.Action)
	return &message, nil
}

// executeCommand runs a command and returns output with error handling
func (nh *NativeHost) executeCommand(name string, args ...string) ([]byte, error) {
	nh.logger.Printf("Executing: %s %s", name, strings.Join(args, " "))

	cmd := exec.Command(name, args...)
	output, err := cmd.Output()

	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			nh.logger.Printf("Command stderr: %s", string(exitError.Stderr))
		}
		return nil, fmt.Errorf("command failed: %w", err)
	}

	return output, nil
}

// getDevices retrieves the list of Tailscale devices
func (nh *NativeHost) getDevices() {
	nh.logger.Printf("Getting Tailscale devices")

	output, err := nh.executeCommand("tailscale", "status", "--json")
	if err != nil {
		nh.logError("Failed to get Tailscale status", err)
		return
	}

	var status TailscaleStatus
	if err := json.Unmarshal(output, &status); err != nil {
		nh.logError("Failed to parse Tailscale status", err)
		return
	}

	devices := nh.filterOnlineDevices(status.Peer)
	nh.logger.Printf("Found %d online devices", len(devices))

	nh.sendMessage(Response{Success: true, Data: devices})
}

// normalizeOS normalizes OS names to standard values for icon mapping
func (nh *NativeHost) normalizeOS(os string) string {
	switch strings.ToLower(os) {
	case "ios":
		return "ios"
	case "macos", "darwin":
		return "macos"
	case "windows":
		return "windows"
	case "linux":
		return "linux"
	default:
		nh.logger.Printf("Unknown OS: %s, defaulting to linux", os)
		return "linux" // Default fallback
	}
}

// filterOnlineDevices filters and returns only online, non-exit-node, taildrop enabled devices
func (nh *NativeHost) filterOnlineDevices(peers map[string]TailscalePeer) []Device {
	var devices []Device
	for _, peer := range peers {
		if peer.Online && !peer.ExitNodeOption && peer.TaildropTarget == TaildropTargetAvailable {
			peerDnsName := strings.Split(peer.DNSName, ".")
			deviceName := ""
			if len(peerDnsName) == 0 {
				deviceName = peer.HostName
			} else {
				deviceName = peerDnsName[0]
			}
			devices = append(devices, Device{
				Name:   deviceName,
				ID:     peer.ID,
				Online: peer.Online,
				OS:     nh.normalizeOS(peer.OS), // Include normalized OS
			})
		}
	}
	return devices
}

// validateSendFileRequest validates the send file request parameters
func (nh *NativeHost) validateSendFileRequest(deviceName, imageData, fileName string) error {
	if deviceName == "" {
		return fmt.Errorf("device name is required")
	}
	if imageData == "" {
		return fmt.Errorf("image data is required")
	}
	if fileName == "" {
		return fmt.Errorf("file name is required")
	}
	if !strings.Contains(imageData, DataURLSeparator) {
		return fmt.Errorf("invalid image data format")
	}
	return nil
}

// decodeImageData decodes base64 image data from data URL
func (nh *NativeHost) decodeImageData(imageData string) ([]byte, error) {
	parts := strings.SplitN(imageData, DataURLSeparator, 2)
	if len(parts) != 2 {
		return nil, fmt.Errorf("invalid data URL format")
	}

	data, err := base64.StdEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, fmt.Errorf("failed to decode base64: %w", err)
	}

	return data, nil
}

// createTempFile creates a temporary file with decoded data
func (nh *NativeHost) createTempFile(data []byte, fileName string, imageType string) (string, error) {
	ext := filepath.Ext(fileName)
	if len(ext) == 0 {
		// image type is extracted from Blob.type
		extFromImageType := strings.Split(imageType, "/")
		if len(extFromImageType) > 1 {
			ext = "." + extFromImageType[1]
		} else {
			ext = ".jpg"
		}
	}
	tmpFile, err := os.CreateTemp("", TempFilePattern+ext)
	if err != nil {
		return "", fmt.Errorf("failed to create temp file: %w", err)
	}
	defer tmpFile.Close()

	if _, err := tmpFile.Write(data); err != nil {
		os.Remove(tmpFile.Name())
		return "", fmt.Errorf("failed to write temp file: %w", err)
	}

	return tmpFile.Name(), nil
}

// sendFile sends a file to a Tailscale device
func (nh *NativeHost) sendFile(deviceName, imageData, fileName string, imageType string) {
	nh.logger.Printf("Sending file %s to device %s", fileName, deviceName)

	// Validate request
	if err := nh.validateSendFileRequest(deviceName, imageData, fileName); err != nil {
		nh.logError("Invalid send file request", err)
		return
	}

	// Decode image data
	data, err := nh.decodeImageData(imageData)
	if err != nil {
		nh.logError("Failed to decode image data", err)
		return
	}

	// Create temporary file
	tmpFilePath, err := nh.createTempFile(data, fileName, imageType)
	if err != nil {
		nh.logError("Failed to create temporary file", err)
		return
	}
	defer func() {
		if err := os.Remove(tmpFilePath); err != nil {
			nh.logger.Printf("WARNING: Failed to remove temp file: %v", err)
		}
	}()

	// Send file via Tailscale
	destination := deviceName + ":"
	if _, err := nh.executeCommand("tailscale", "file", "cp", tmpFilePath, destination); err != nil {
		nh.logError("Failed to send file via Tailscale", err)
		return
	}

	nh.logger.Printf("File sent successfully to %s", deviceName)
	nh.sendMessage(Response{Success: true})
}

// handleMessage processes incoming messages
func (nh *NativeHost) handleMessage(message *Message) {
	switch message.Action {
	case "get_devices":
		nh.getDevices()
	case "send_file":
		nh.sendFile(message.DeviceName, message.ImageData, message.FileName, message.ImageType)
	default:
		nh.logError("Unknown action", fmt.Errorf("action: %s", message.Action))
	}
}

// run starts the native host
func (nh *NativeHost) run() {
	nh.logger.Printf("=== Tailscale Image Sender Native Host Started ===")

	defer func() {
		if r := recover(); r != nil {
			nh.logger.Printf("PANIC: %v", r)
			nh.sendMessage(Response{Success: false, Error: fmt.Sprintf("Host crashed: %v", r)})
			os.Exit(1)
		}
		nh.logger.Printf("=== Host execution completed ===")
	}()

	message, err := nh.readMessage()
	if err != nil {
		nh.logError("Failed to read message", err)
		os.Exit(1)
	}

	nh.handleMessage(message)
}

func main() {
	host, err := NewNativeHost()
	if err != nil {
		log.Fatalf("Failed to create native host: %v", err)
	}

	host.run()
}
