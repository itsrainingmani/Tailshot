const NATIVE_HOST_NAME = 'com.bitandbang.tailscale_image_sender';
const IMAGE_FETCH_TIMEOUT_MS = 30000;

// Cross-browser API compatibility
const browserAPI = typeof browser !== 'undefined' ? browser : chrome;

// Create context menu on install
browserAPI.runtime.onInstalled.addListener(() => {
	browserAPI.contextMenus.create({
		id: 'sendWithTailscale',
		title: 'Send with Tailscale',
		contexts: ['image'],
	});
});

// Handle context menu click - directly open popup with image URL
browserAPI.contextMenus.onClicked.addListener((info, tab) => {
	if (info.menuItemId === 'sendWithTailscale' && info.srcUrl) {
		browserAPI.windows.create({
			url: browserAPI.runtime.getURL(
				`popup.html?imageUrl=${encodeURIComponent(info.srcUrl)}`
			),
			type: 'popup',
			width: 350,
			height: 450,
			focused: true,
		});
	}
});

// Handle all native messaging in background
browserAPI.runtime.onMessage.addListener((request, sender, sendResponse) => {
	if (request.action === 'get_devices') {
		sendNativeMessage({ action: 'get_devices' })
			.then(sendResponse)
			.catch((error) => sendResponse({ success: false, error: error.message }));
		return true;
	}

	if (request.action === 'send_image') {
		sendImageToDevice(request.imageUrl, request.device)
			.then(sendResponse)
			.catch((error) => sendResponse({ success: false, error: error.message }));
		return true;
	}
});

// Simplified image sending
async function sendImageToDevice(imageUrl, device) {
	try {
		const response = await fetchImage(imageUrl);
		const imageBlob = await response.blob();
		const contentType = imageBlob.type || response.headers.get('content-type') || '';

		if (contentType && !contentType.toLowerCase().startsWith('image/')) {
			return {
				success: false,
				error: `Expected an image, got ${contentType}`,
			};
		}

		const base64data = await blobToBase64(imageBlob);
		const fileName = getFileName(imageUrl);

		return sendNativeMessage({
			action: 'send_file',
			device_name: device.name,
			image_data: base64data,
			file_name: fileName,
			image_type: contentType,
		});
	} catch (error) {
		return { success: false, error: error.message };
	}
}

async function fetchImage(imageUrl) {
	const controller = new AbortController();
	const timeoutId = setTimeout(() => controller.abort(), IMAGE_FETCH_TIMEOUT_MS);

	try {
		const response = await fetch(imageUrl, {
			cache: 'no-store',
			credentials: 'include',
			signal: controller.signal,
		});

		if (!response.ok) {
			throw new Error(`Image request failed with HTTP ${response.status}`);
		}

		return response;
	} catch (error) {
		if (error.name === 'AbortError') {
			throw new Error('Timed out while downloading image');
		}
		throw error;
	} finally {
		clearTimeout(timeoutId);
	}
}

function sendNativeMessage(message) {
	if (typeof browser !== 'undefined' && browser.runtime?.sendNativeMessage) {
		return browser.runtime
			.sendNativeMessage(NATIVE_HOST_NAME, message)
			.then(handleNativeResponse)
			.catch((error) => ({ success: false, error: error.message }));
	}

	return new Promise((resolve) => {
		chrome.runtime.sendNativeMessage(NATIVE_HOST_NAME, message, (response) => {
			resolve(handleNativeResponse(response));
		});
	});
}

// Unified native response handler
function handleNativeResponse(response) {
	const lastError = browserAPI.runtime.lastError;
	if (lastError) return { success: false, error: lastError.message };
	if (!response) return { success: false, error: 'No response from native host' };
	if (!response.success) return { success: false, error: response.error || 'Unknown error' };
	return response;
}

// Utility functions
function getFileName(url) {
	try {
		const path = new URL(url).pathname;
		return path.substring(path.lastIndexOf('/') + 1) || 'image.jpg';
	} catch (e) {
		return 'image.jpg';
	}
}

function blobToBase64(blob) {
	return new Promise((resolve, reject) => {
		const reader = new FileReader();
		reader.onloadend = () => resolve(reader.result);
		reader.onerror = reject;
		reader.readAsDataURL(blob);
	});
}
