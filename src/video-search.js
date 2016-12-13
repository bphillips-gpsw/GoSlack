var fetch = require('isomorphic-fetch');

var PLAYLISTS = 'https://api.gopro.com/v2/channels/feed/playlists.json?platform=web';

function videoSearch(query) {
  return fetch(PLAYLISTS)
    .then(function(res) {return res.json();})
    .then(function(data) {
      var playLists = data.playlists;
      var playListCount = playLists.length;
      var randomPlaylist = playLists[Math.floor(Math.random() * playListCount)];
      var title = randomPlaylist.permalink;

      var playListURL = 'https://api.gopro.com/v2/channels/feed/playlists/' + title + '.json?platform=web';
      var link = '';

      return fetch(playListURL)
              .then(function(res) {return res.json();})
              .then(function(data) {
                link = data.media[Math.floor(Math.random() * data.media.length)].web_link;
                while(!link) {
                  link = data.media[Math.floor(Math.random() * data.media.length)].web_link;
                }
                return link;
              });
    });
};


// usage
videoSearch()
  .then(function(url){
    console.log('Final URL:', url);
  });
