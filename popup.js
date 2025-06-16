// Get image URL from URL parameters
const urlParams = new URLSearchParams(window.location.search);
const imageUrl = urlParams.get('imageUrl');

// DOM elements
const statusEl = document.getElementById('status');
const filenameEl = document.getElementById('filename');
const deviceListEl = document.getElementById('device-list');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
	if (!imageUrl) {
		showStatus('No image found', 'error');
		return;
	}

	filenameEl.textContent = getFileName(imageUrl);
	loadDevices();
});

// Load and display devices
async function loadDevices() {
	showStatus('Loading devices...');

	try {
		const response = await chrome.runtime.sendMessage({
			action: 'get_devices',
		});

		if (!response.success) {
			showStatus(`Error: ${response.error}`, 'error');
			return;
		}

		const onlineDevices = response.data.filter((d) => d.online);

		if (onlineDevices.length === 0) {
			showStatus('No online devices found', 'error');
			return;
		}

		displayDevices(onlineDevices);
		statusEl.style.display = 'none';
	} catch (error) {
		showStatus('Failed to load devices', 'error');
	}
}

// Display device list
function displayDevices(devices) {
	deviceListEl.innerHTML = '';

	devices.forEach((device) => {
		const deviceEl = document.createElement('div');
		deviceEl.className = 'device-item';
		deviceEl.innerHTML = `
			<div class="device-status"></div>
			<div class="device-name">${device.name}</div>
		`;

		deviceEl.onclick = () => sendToDevice(device);
		deviceListEl.appendChild(deviceEl);
	});

	deviceListEl.style.display = 'block';
}

// Send image to selected device
async function sendToDevice(device) {
	showStatus(`Sending to ${device.name}...`);
	deviceListEl.style.display = 'none';

	try {
		const response = await chrome.runtime.sendMessage({
			action: 'send_image',
			imageUrl: imageUrl,
			device: device,
		});

		if (response.success) {
			showStatus('✓ Sent successfully!', 'success');
			setTimeout(() => window.close(), 1500);
		} else {
			showStatus(`Error: ${response.error}`, 'error');
			setTimeout(() => {
				statusEl.style.display = 'none';
				deviceListEl.style.display = 'block';
			}, 2000);
		}
	} catch (error) {
		showStatus('Failed to send image', 'error');
	}
}

// Unified status display
function showStatus(message, type = 'loading') {
	statusEl.textContent = message;
	statusEl.className = `status ${type}`;
	statusEl.style.display = 'block';
}

// Utility
function getFileName(url) {
	try {
		const path = new URL(url).pathname;
		return (
			decodeURIComponent(path.substring(path.lastIndexOf('/') + 1)) ||
			'image.jpg'
		);
	} catch (e) {
		return 'image.jpg';
	}
}
