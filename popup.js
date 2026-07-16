// Get image URL from URL parameters
const urlParams = new URLSearchParams(window.location.search);
const imageUrl = urlParams.get('imageUrl');

// DOM elements
const statusEl = document.getElementById('status');
const filenameEl = document.getElementById('filename');
const filemetaEl = document.getElementById('filemeta');
const fileThumbEl = document.getElementById('file-thumb');
const deviceListEl = document.getElementById('device-list');
const headerDotEl = document.getElementById('header-dot');
const headerTextEl = document.getElementById('header-text');
const cancelEl = document.getElementById('cancel');

// OS Icons - Lucide SVG icons
const OS_ICONS = {
	windows: `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-monitor-icon lucide-monitor"><rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" y2="21"/></svg>`,
	macos: `
		<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-laptop-icon lucide-laptop"><path d="M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"/><path d="M20.054 15.987H3.946"/></svg>
	`,
	linux: `
		<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-server-icon lucide-server"><rect width="20" height="8" x="2" y="2" rx="2" ry="2"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2"/><line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/></svg>
	`,
	android: `
		<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-smartphone-icon lucide-smartphone"><rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/></svg>
	`,
	ios: `
		<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-smartphone-icon lucide-smartphone"><rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/></svg>
	`,
	default: `
		<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-laptop-icon lucide-laptop"><path d="M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"/><path d="M20.054 15.987H3.946"/></svg>
	`,
};

const OS_LABELS = {
	windows: 'Windows',
	macos: 'macOS',
	linux: 'Linux',
	android: 'Android',
	ios: 'iOS',
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
	cancelEl.onclick = () => window.close();

	if (!imageUrl) {
		setHeaderStatus('No image', false);
		showStatus('No image found', 'error');
		return;
	}

	const filename = getFileName(imageUrl);
	filenameEl.textContent = filename;
	filenameEl.title = filename;
	filemetaEl.textContent = getFileMeta(imageUrl, filename);
	loadThumbnail(imageUrl);
	loadDevices();
});

// Load and display devices
async function loadDevices() {
	setHeaderStatus('Connecting…', false);
	showStatus('Loading devices…');

	try {
		const response = await sendRuntimeMessage({
			action: 'get_devices',
		});

		if (!response?.success) {
			setHeaderStatus('Offline', false);
			showStatus(`Error: ${response?.error || 'No response from extension'}`, 'error');
			return;
		}

		const devices = response.data || [];

		if (devices.length === 0) {
			setHeaderStatus('Connected', true);
			showStatus('No Taildrop devices found', 'error');
			return;
		}

		setHeaderStatus('Connected', true);
		displayDevices(devices);
		statusEl.style.display = 'none';
	} catch (error) {
		setHeaderStatus('Offline', false);
		showStatus('Failed to load devices', 'error');
	}
}

// Display device list
let lastDevices = [];

function displayDevices(devices) {
	lastDevices = devices;
	deviceListEl.innerHTML = '';

	const sorted = [...devices].sort(
		(a, b) => Number(Boolean(b.online)) - Number(Boolean(a.online))
	);

	sorted.forEach((device) => {
		const deviceEl = document.createElement('div');
		deviceEl.className = 'device-item';
		if (!device.online) {
			deviceEl.classList.add('offline');
			deviceEl.title = 'Tailscale reports this device as offline; Taildrop will still try to send.';
		}

		const osIconEl = document.createElement('div');
		osIconEl.className = 'device-os-icon';
		osIconEl.innerHTML = getOSIcon(device.os);

		const bodyEl = document.createElement('div');
		bodyEl.className = 'device-body';

		const titleRowEl = document.createElement('div');
		titleRowEl.className = 'device-title-row';

		const nameEl = document.createElement('div');
		nameEl.className = 'device-name';
		nameEl.textContent = device.name;
		titleRowEl.appendChild(nameEl);

		const subEl = document.createElement('div');
		subEl.className = 'device-sub';
		subEl.textContent = `${getOSLabel(device.os)} · ${device.online ? 'online' : 'offline'}`;

		bodyEl.append(titleRowEl, subEl);

		const dotEl = document.createElement('div');
		dotEl.className = 'device-status';
		if (device.online) {
			dotEl.classList.add('online');
		}

		deviceEl.append(osIconEl, bodyEl, dotEl);

		deviceEl.onclick = () => sendToDevice(device, deviceEl);
		deviceListEl.appendChild(deviceEl);
	});

	deviceListEl.style.display = 'flex';
}

// Get OS icon based on device OS
function getOSIcon(os) {
	if (!os) return OS_ICONS.default;

	if (os.includes('windows')) return OS_ICONS.windows;
	if (os.includes('macos')) return OS_ICONS.macos;
	if (os.includes('linux')) return OS_ICONS.linux;
	if (os.includes('android')) return OS_ICONS.android;
	if (os.includes('ios')) return OS_ICONS.ios;

	return OS_ICONS.default;
}

function getOSLabel(os) {
	if (!os) return 'Device';

	for (const [key, label] of Object.entries(OS_LABELS)) {
		if (os.includes(key)) return label;
	}

	return os.charAt(0).toUpperCase() + os.slice(1);
}

// Swap a device row between its idle layout and the sending/sent layout
function setRowSending(deviceEl, stateText) {
	deviceEl.classList.add('sending');
	deviceEl.classList.remove('offline');

	const bodyEl = deviceEl.querySelector('.device-body');
	const titleRowEl = bodyEl.querySelector('.device-title-row');
	deviceEl.querySelector('.device-status')?.remove();
	bodyEl.querySelector('.device-sub')?.remove();

	const stateEl = document.createElement('div');
	stateEl.className = 'device-send-state';
	stateEl.textContent = stateText;
	titleRowEl.appendChild(stateEl);

	const trackEl = document.createElement('div');
	trackEl.className = 'progress-track';
	const fillEl = document.createElement('div');
	fillEl.className = 'progress-fill';
	trackEl.appendChild(fillEl);
	bodyEl.appendChild(trackEl);
}

// Send image to selected device
async function sendToDevice(device, deviceEl) {
	if (document.body.classList.contains('busy')) return;

	document.body.classList.add('busy');
	statusEl.style.display = 'none';
	setRowSending(deviceEl, 'Sending…');

	try {
		await requestImageHostPermission(imageUrl);

		const response = await sendRuntimeMessage({
			action: 'send_image',
			imageUrl: imageUrl,
			device: device,
		});

		if (response?.success) {
			deviceEl.classList.remove('sending');
			deviceEl.classList.add('sent');
			deviceEl.querySelector('.device-send-state').textContent = 'Sent';
			setTimeout(() => window.close(), 1500);
		} else {
			showSendError(`Error: ${response?.error || 'No response from extension'}`);
		}
	} catch (error) {
		showSendError(error.message || 'Failed to send image');
	}
}

// Show a send failure, then restore the device list
function showSendError(message) {
	deviceListEl.style.display = 'none';
	showStatus(message, 'error');
	setTimeout(() => {
		statusEl.style.display = 'none';
		document.body.classList.remove('busy');
		displayDevices(lastDevices);
	}, 2000);
}

// Unified status display
function showStatus(message, type = 'loading') {
	statusEl.textContent = message;
	statusEl.className = `status ${type}`;
	statusEl.style.display = 'block';
}

// Header connection indicator
function setHeaderStatus(text, online) {
	headerTextEl.textContent = text;
	headerDotEl.className = online ? 'dot online' : 'dot';
}

// Show the actual image in the file card when it loads
function loadThumbnail(url) {
	const img = new Image();
	img.onload = () => {
		fileThumbEl.style.backgroundImage = `url("${url.replace(/"/g, '%22')}")`;
		fileThumbEl.querySelector('span').style.display = 'none';
	};
	img.src = url;
}

async function requestImageHostPermission(url) {
	const origin = getOriginPattern(url);
	if (!origin || typeof chrome === 'undefined' || !chrome.permissions?.request) {
		return;
	}

	const granted = await chrome.permissions.request({ origins: [origin] });
	if (!granted) {
		throw new Error('Permission to download this image was not granted');
	}
}

function getOriginPattern(url) {
	try {
		const parsedUrl = new URL(url);
		if (parsedUrl.protocol !== 'http:' && parsedUrl.protocol !== 'https:') {
			return null;
		}
		return `${parsedUrl.protocol}//${parsedUrl.host}/*`;
	} catch (e) {
		return null;
	}
}

function sendRuntimeMessage(message) {
	if (typeof browser !== 'undefined' && browser.runtime?.sendMessage) {
		return browser.runtime.sendMessage(message);
	}

	return new Promise((resolve, reject) => {
		chrome.runtime.sendMessage(message, (response) => {
			const lastError = chrome.runtime.lastError;
			if (lastError) {
				reject(new Error(lastError.message));
				return;
			}
			resolve(response);
		});
	});
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

function getFileMeta(url, filename) {
	const parts = [];

	const dot = filename.lastIndexOf('.');
	if (dot > 0 && dot < filename.length - 1) {
		parts.push(filename.substring(dot + 1).toLowerCase());
	}

	try {
		parts.push(new URL(url).hostname);
	} catch (e) {
		// ignore unparseable URLs
	}

	return parts.join(' · ') || 'image';
}
