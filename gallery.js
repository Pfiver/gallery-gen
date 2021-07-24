import PhotoSwipeLightbox from './photoswipe-lightbox.esm.min.js';

if (false) {

  // https://photoswipe.com/v5/docs/getting-started/

  const lightbox = new PhotoSwipeLightbox({
    gallerySelector: '.pswp-gallery',
    childSelector: 'a',
    pswpModule: './photoswipe.esm.js',
    pswpCSS: './photoswipe.css',
    bgOpacity: 0.95
  });
  lightbox.init();

} else {

  // https://photoswipe.com/v5/docs/native-fullscreen-on-open/

  const fullscreenAPI = getFullscreenAPI();
  const pswpContainer = getContainer();

  const lightbox = new PhotoSwipeLightbox({
    gallerySelector: '.pswp-gallery',
    childSelector: 'a',
    pswpModule: './photoswipe.esm.min.js',
    pswpCSS: './photoswipe.css',
    bgOpacity: 0.95,

    openPromise: getFullscreenPromise,
    appendToEl: fullscreenAPI ? pswpContainer : document.body,

    showAnimationDuration: 0,
    hideAnimationDuration: 0,

    preloadFirstSlide: false
  });
  lightbox.on('uiRegister', function() {
    lightbox.pswp.ui.registerElement({
      name: 'custom-caption',
      order: 9,
      isButton: false,
      appendTo: 'root',
      html: 'Caption text',
      onInit: (el, pswp) => {
        lightbox.pswp.on('change', () => {
          const currSlideElement = lightbox.pswp.currSlide.data.element;
          let captionHTML = '';
          if (currSlideElement) {
            captionHTML = currSlideElement.querySelector('img').getAttribute('alt');
          }
          el.innerHTML = captionHTML || '';
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
  };


  function getFullscreenPromise() {
    return new Promise((resolve) => {
      if (!fullscreenAPI || fullscreenAPI.isFullscreen()) {
        resolve();
        return;
      }

      document.addEventListener(fullscreenAPI.change, (event) => {
        pswpContainer.style.display = 'block';
        // delay to make sure that browser fullscreen animation is finished
        setTimeout(function() {
          resolve();
        }, 300);
      }, { once: true });

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

}

// vim: sw=2 ts=2 et
