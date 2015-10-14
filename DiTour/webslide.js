
// web pages can post a message to DiTour to resize the slide passing the new width and height
function resizeDiTourSlide() {
	var size = {}
	if (document.width) {
		size = {width: document.width, height: document.height}
	} else {
		// use the body size if the document size is undefined (e.g. for documents generating content via XSLT)
		var body = document.querySelector('body');
		size = {width: body.clientWidth, height: body.clientHeight}
	}
	window.webkit.messageHandlers.resize.postMessage(size);
	return size
}

