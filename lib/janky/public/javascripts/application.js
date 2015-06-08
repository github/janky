$(function(){
  function refresh() {
    $('.builds').load(location.pathname + ' .builds', function() {
      $('.relatize').relatize()
    })
  }

  setInterval(refresh, 5000)
  $('.relatize').relatize()
})
