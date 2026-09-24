jq(function() {
    var $selected = jq('#login-location-select');
    if (!$selected.length) {
        return;
    }
    var facilityNames = {};
    jq('.visit-location-select .location-list-item').each(function() {
        facilityNames[jq(this).attr('value')] = jq(this).text().trim();
    });
    $selected.find('.login-location-item').each(function() {
        var $item = jq(this);
        var match = this.className.match(/login-location-item-(\d+)/);
        if (!match) {
            return;
        }
        var facility = facilityNames[match[1]];
        if (!facility) {
            return;
        }
        var text = $item.text().trim();
        if (text.indexOf(facility + ' ') === 0) {
            $item.text(text.substring(facility.length + 1));
        } else {
            var suffix = ' | ' + facility;
            if (text.indexOf(suffix) > 0) {
                $item.text(text.substring(0, text.indexOf(suffix)));
            }
        }
    });
});