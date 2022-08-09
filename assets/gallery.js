import PhotoSwipeLightbox from './photoswipe-lightbox.esm.min.js';

// https://photoswipe.com/v5/docs/native-fullscreen-on-open/

const fullscreenAPI = getFullscreenAPI();
const pswpContainer = getContainer();

const lightbox = new PhotoSwipeLightbox({
    pswpModule: () => import('./photoswipe.esm.min.js'),
    gallery: '.gallery',
    children: 'a',

    openPromise: getFullscreenPromise,
    appendToEl: fullscreenAPI ? pswpContainer : document.body,

    showAnimationDuration: 0,
    hideAnimationDuration: 0,

    preloadFirstSlide: false
});
lightbox.on('uiRegister', function () {
    lightbox.pswp.ui.registerElement({
        name: 'image-id',
        className: 'gallery-image-id',
        order: 6,
        isButton: false,
        appendTo: 'bar',
        onInit: (el, pswp) => {
            lightbox.pswp.on('change', () => {
                const currSlide = lightbox.pswp.currSlide.data.element;
                if (currSlide) {
                    el.innerHTML = currSlide.getAttribute('data-gallery-image-id');
                }
            });
        }
    });
    lightbox.pswp.ui.registerElement({
        name: 'image-caption',
        className: 'gallery-image-caption',
        order: 9,
        isButton: false,
        appendTo: 'root',
        onInit: (el, pswp) => {
            lightbox.pswp.on('change', () => {
                const currSlide = lightbox.pswp.currSlide.data.element;
                if (currSlide) {
                    el.innerHTML = currSlide.getAttribute('data-gallery-image-name');
                }
            });
        }
    });
});
lightbox.on('close', () => {
    pswpContainer.style.display = 'none';
    if (fullscreenAPI && fullscreenAPI.isFullscreen()) {
        fullscreenAPI.exit();
    }
});
document.addEventListener('fullscreenchange', (event) => {
    if (!document.fullscreenElement) {
        lightbox.pswp.close();
    }
});
lightbox.init();


function getFullscreenAPI() {
    let api;
    let enterFS;
    let exitFS;
    let elementFS;
    let changeEvent;
    let errorEvent;

    if (document.documentElement.requestFullscreen) {
        enterFS = 'requestFullscreen';
        exitFS = 'exitFullscreen';
        elementFS = 'fullscreenElement';
        changeEvent = 'fullscreenchange';
        errorEvent = 'fullscreenerror';
    } else if (document.documentElement.webkitRequestFullscreen) {
        enterFS = 'webkitRequestFullscreen';
        exitFS = 'webkitExitFullscreen';
        elementFS = 'webkitFullscreenElement';
        changeEvent = 'webkitfullscreenchange';
        errorEvent = 'webkitfullscreenerror';
    }

    if (enterFS) {
        api = {
            request: function (el) {
                if (enterFS === 'webkitRequestFullscreen') {
                    el[enterFS](Element.ALLOW_KEYBOARD_INPUT);
                } else {
                    el[enterFS]();
                }
            },
            exit: function () {
                return document[exitFS]();
            },
            isFullscreen: function () {
                return document[elementFS];
            },
            change: changeEvent,
            error: errorEvent
        };
    }
    return api;
}

function getFullscreenPromise() {
    return new Promise((resolve) => {
        if (!fullscreenAPI || fullscreenAPI.isFullscreen()) {
            resolve();
            return;
        }
        document.addEventListener(fullscreenAPI.change, (event) => {
            pswpContainer.style.display = 'block';
            resolve();
        }, {once: true});
        fullscreenAPI.request(pswpContainer);
    });
}

function getContainer() {
    const pswpContainer = document.createElement('div');
    pswpContainer.style.background = '#000';
    pswpContainer.style.width = '100%';
    pswpContainer.style.height = '100%';
    pswpContainer.style.display = 'none';
    document.body.appendChild(pswpContainer);
    return pswpContainer;
}

function addStylesheet(path) {
    let css = document.createElement("link");
    css.rel = "stylesheet";
    let url = new URL(path, import.meta.url);
    css.href = url.href;
    document.body.appendChild(css);
    new URL("gallery.css", import.meta.url)
}

addStylesheet("gallery.css");
addStylesheet("photoswipe.css");

// vim: sw=2 ts=2 et
