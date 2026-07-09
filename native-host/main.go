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
	"runtime"
	"strings"
)

// Constants
const (
	LogFileName      = "debug.log"
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
	logger  *log.Logger
	logFile *os.File
}

// NewNativeHost creates a new native host instance
func NewNativeHost() (*NativeHost, error) {
	logFile, err := os.OpenFile(LogFileName, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %w", err)
	}

	logger := log.New(logFile, "", log.LstdFlags|log.Lshortfile)

	return &NativeHost{logger: logger, logFile: logFile}, nil
}

func (nh *NativeHost) close() {
	if nh.logFile != nil {
		nh.logFile.Close()
	}
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

func (nh *NativeHost) executeCommandWithInput(input io.Reader, name string, args ...string) ([]byte, error) {
	nh.logger.Printf("Executing with stdin: %s %s", name, strings.Join(args, " "))

	cmd := exec.Command(name, args...)
	cmd.Stdin = input
	output, err := cmd.CombinedOutput()
	if err != nil {
		if len(output) > 0 {
			nh.logger.Printf("Command output: %s", string(output))
		}
		return nil, fmt.Errorf("command failed: %w", err)
	}

	return output, nil
}

func tailscaleCommand() string {
	if path, err := exec.LookPath("tailscale"); err == nil {
		return path
	}

	if runtime.GOOS != "windows" {
		return "tailscale"
	}

	for _, baseDir := range []string{os.Getenv("ProgramFiles"), os.Getenv("ProgramFiles(x86)")} {
		if baseDir == "" {
			continue
		}

		candidate := filepath.Join(baseDir, "Tailscale", "tailscale.exe")
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	return "tailscale"
}

// getDevices retrieves the list of Tailscale devices
func (nh *NativeHost) getDevices() {
	nh.logger.Printf("Getting Tailscale devices")

	output, err := nh.executeCommand(tailscaleCommand(), "status", "--json")
	if err != nil {
		nh.logError("Failed to get Tailscale status", err)
		return
	}

	var status TailscaleStatus
	if err := json.Unmarshal(output, &status); err != nil {
		nh.logError("Failed to parse Tailscale status", err)
		return
	}

	devices := nh.filterTaildropDevices(status.Peer)
	nh.logger.Printf("Found %d Taildrop-capable devices", len(devices))

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

// filterTaildropDevices filters and returns non-exit-node peers that can receive Taildrop files.
func (nh *NativeHost) filterTaildropDevices(peers map[string]TailscalePeer) []Device {
	var devices []Device
	for _, peer := range peers {
		canReceiveTaildrop := peer.TaildropTarget == TaildropTargetAvailable || peer.TaildropTarget == TaildropTargetOffline
		if canReceiveTaildrop && !peer.ExitNodeOption {
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

// imageDataReader returns a stream that decodes base64 image data from a data URL.
func (nh *NativeHost) imageDataReader(imageData string) (io.Reader, error) {
	parts := strings.SplitN(imageData, DataURLSeparator, 2)
	if len(parts) != 2 {
		return nil, fmt.Errorf("invalid data URL format")
	}

	if !strings.HasPrefix(strings.ToLower(parts[0]), "data:") {
		return nil, fmt.Errorf("invalid data URL header")
	}

	return base64.NewDecoder(base64.StdEncoding, strings.NewReader(parts[1])), nil
}

func sanitizeFileName(fileName string, imageType string) string {
	name := filepath.Base(fileName)
	name = strings.TrimSpace(name)
	if name == "." || name == string(filepath.Separator) || name == "" {
		name = "image"
	}

	if filepath.Ext(name) == "" {
		extFromImageType := strings.Split(imageType, "/")
		if len(extFromImageType) > 1 && extFromImageType[1] != "" {
			name += "." + strings.Split(extFromImageType[1], ";")[0]
		} else {
			name += ".jpg"
		}
	}

	return name
}

// sendFile sends a file to a Tailscale device
func (nh *NativeHost) sendFile(deviceName, imageData, fileName string, imageType string) {
	nh.logger.Printf("Sending file %s to device %s", fileName, deviceName)

	// Validate request
	if err := nh.validateSendFileRequest(deviceName, imageData, fileName); err != nil {
		nh.logError("Invalid send file request", err)
		return
	}

	imageReader, err := nh.imageDataReader(imageData)
	if err != nil {
		nh.logError("Failed to prepare image data", err)
		return
	}

	safeFileName := sanitizeFileName(fileName, imageType)
	destination := deviceName + ":"
	if _, err := nh.executeCommandWithInput(imageReader, tailscaleCommand(), "file", "cp", "--name", safeFileName, "-", destination); err != nil {
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
	defer host.close()

	host.run()
}
