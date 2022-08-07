// Issue sync form support

  function updateSyncFrom(url, el) {
    return $.ajax({
      url: url,
      type: 'post',
      data: $('#issue_sync_selected_trackers_').serialize()
    });
  }
