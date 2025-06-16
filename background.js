const NATIVE_HOST_NAME = 'com.bitandbang.tailscale_image_sender';

// Create context menu on install
chrome.runtime.onInstalled.addListener(() => {
	chrome.contextMenus.create({
		id: 'sendWithTailscale',
		title: 'Send with Tailscale',
		contexts: ['image'],
	});
});

// Handle context menu click - directly open popup with image URL
chrome.contextMenus.onClicked.addListener((info, tab) => {
	if (info.menuItemId === 'sendWithTailscale' && info.srcUrl) {
		chrome.windows.create({
			url: chrome.runtime.getURL(
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
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
	if (request.action === 'get_devices') {
		chrome.runtime.sendNativeMessage(
			NATIVE_HOST_NAME,
			{ action: 'get_devices' },
			(response) => {
				sendResponse(handleNativeResponse(response));
			}
		);
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
		let options;
		if (imageUrl.includes('twimg')) {
			options = {
				headers: {
					'User-Agent':
						'Mozille/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
					Accept: '*/*',
					Referer: 'https://x.com/',
					'Accept-Language': 'en-US,en;q=0.9',
					'Cache-Control': 'no-cache',
					Pragma: 'no-cache',
				},
			};
		}
		const response = await fetch(imageUrl, options);
		const imageBlob = await response.blob();
		const base64data = await blobToBase64(imageBlob);
		const fileName = getFileName(imageUrl);

		return new Promise((resolve) => {
			chrome.runtime.sendNativeMessage(
				NATIVE_HOST_NAME,
				{
					action: 'send_file',
					device_name: device.name,
					image_data: base64data,
					file_name: fileName,
					image_type: imageBlob.type,
				},
				(response) => {
					resolve(handleNativeResponse(response));
				}
			);
		});
	} catch (error) {
		return { success: false, error: error.message };
	}
}

// Unified native response handler
function handleNativeResponse(response) {
	if (chrome.runtime.lastError) {
		return { success: false, error: chrome.runtime.lastError.message };
	}
	if (!response) {
		return { success: false, error: 'No response from native host' };
	}
	if (!response.success) {
		return { success: false, error: response.error || 'Unknown error' };
	}
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
