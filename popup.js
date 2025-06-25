// Get image URL from URL parameters
const urlParams = new URLSearchParams(window.location.search);
const imageUrl = urlParams.get('imageUrl');

// DOM elements
const statusEl = document.getElementById('status');
const filenameEl = document.getElementById('filename');
const deviceListEl = document.getElementById('device-list');

// OS Icons - Placeholders for Lucide SVG icons
const OS_ICONS = {
	windows: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-monitor-icon lucide-monitor"><rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" y2="21"/></svg>`,
	macos: `
		<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-laptop-icon lucide-laptop"><path d="M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"/><path d="M20.054 15.987H3.946"/></svg>
	`,
	linux: `
		<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-server-icon lucide-server"><rect width="20" height="8" x="2" y="2" rx="2" ry="2"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2"/><line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/></svg>
	`,
	android: `
		<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-phone-icon lucide-phone"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg>
	`,
	ios: `
		<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-smartphone-icon lucide-smartphone"><rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/></svg>
	`,
	default: `
		<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-laptop-icon lucide-laptop"><path d="M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"/><path d="M20.054 15.987H3.946"/></svg>
	`,
};

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
			<div class="device-os-icon">${getOSIcon(device.os)}</div>
		`;

		deviceEl.onclick = () => sendToDevice(device);
		deviceListEl.appendChild(deviceEl);
	});

	deviceListEl.style.display = 'block';
}

// Get OS icon based on device OS
function getOSIcon(os) {
	console.log(os);
	if (!os) return OS_ICONS.default;

	if (os.includes('windows')) return OS_ICONS.windows;
	if (os.includes('macos')) return OS_ICONS.macos;
	if (os.includes('linux')) return OS_ICONS.linux;
	if (os.includes('android')) return OS_ICONS.android;
	if (os.includes('ios')) return OS_ICONS.ios;

	return OS_ICONS.default;
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
