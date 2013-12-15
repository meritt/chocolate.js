var IMAGE_QUANTITY = 3;
var TEST_FILE = 'file://' + __dirname + '/files/index.html';

module.exports = {
  'Test init chocko items': function (test) {
    test.open(TEST_FILE)
      .execute(function () {
         var chocko = new chocolate(document.querySelectorAll('img'));
       })
      .assert.numberOfElements('.choco-item ')
      .is(IMAGE_QUANTITY, 'should be ' + IMAGE_QUANTITY + ' choco-item')
      .done();
  },
  'Test choco-show': function (test) {
    test.open(TEST_FILE)
      .execute(function () {
         var imgs = document.querySelectorAll('img');
         var chocko = new chocolate(imgs);
         chocko.open(imgs.length);
       })
      .assert.visible('.choco-show')
      .done();
  },
  'Test choco-close': function (test) {
    test.open(TEST_FILE).execute(function () {
      var imgs = document.querySelectorAll('img');
      var chocko = new chocolate(imgs);
      chocko.open(imgs.length);
      setTimeout(function() {
        chocko.close();
      }, 15);
    });
    test.assert.exists('.choco-overlay');
    test.assert.doesntExist('.choco-show');
    test.done();
  },
  'Test choco-thumbnails': function(test) {
    test.open(TEST_FILE).execute(function() {
      var imgs = document.querySelectorAll('img');
      var chocko = new chocolate(imgs);
      chocko.open(imgs.length);
    });

    test.assert.exists('.choco-show');
    test.assert.exists('.choco-show .choco-thumbnails');
    test.assert.numberOfElements('.choco-show .choco-thumbnails .choco-thumbnail')
               .is(IMAGE_QUANTITY, 'should be ' + IMAGE_QUANTITY + ' choco-thumbnails');
    test.done();
  },
  'Test choco-next from 1 to 2': function (test) {
    test.open(TEST_FILE).execute(function () {
      var imgs = document.querySelectorAll('img');
      var chocko = new chocolate(imgs);
      chocko.open(0, null);
      setTimeout(function() {
        chocko.next();
      }, 500);
    })
    .wait(500)
    .assert.exists('.choco-show .choco-thumbnails .choco-selected')
    .assert.exists('.choco-show .choco-thumbnails .choco-thumbnail:nth-child(2).choco-selected')
    .done();
  },
  'Test choco-next from 2 to 3': function (test) {
    test.open(TEST_FILE).execute(function () {
      var imgs = document.querySelectorAll('img');
      var chocko = new chocolate(imgs);
      chocko.open(1, null);
      setTimeout(function() {
        chocko.next();
      }, 500);
    })
    .wait(500)
    .assert.exists('.choco-show .choco-thumbnails .choco-selected')
    .assert.exists('.choco-show .choco-thumbnails .choco-thumbnail:nth-child(3).choco-selected')
    .done();
  },
  'Test choco-prev from 2 to 1': function (test) {
    test.open(TEST_FILE).execute(function () {
      var imgs = document.querySelectorAll('img');
      var chocko = new chocolate(imgs);
      chocko.open(1, null);
      setTimeout(function() {
        chocko.prev();
      }, 500);
    })
    .wait(1500)
    .assert.exists('.choco-show .choco-thumbnails .choco-selected')
    .assert.exists('.choco-show .choco-thumbnails .choco-thumbnail:nth-child(1).choco-selected')
    .done();
  },
  'Test choco-prev from 3 to 2': function (test) {
    test.open(TEST_FILE).execute(function () {
      var imgs = document.querySelectorAll('img');
      var chocko = new chocolate(imgs);
      chocko.open(2, null);
      setTimeout(function() {
        chocko.prev();
      }, 500);
    })
    .wait(1500)
    .assert.exists('.choco-show .choco-thumbnails .choco-selected')
    .assert.exists('.choco-show .choco-thumbnails .choco-thumbnail:nth-child(2).choco-selected')
    .done();
  }
};