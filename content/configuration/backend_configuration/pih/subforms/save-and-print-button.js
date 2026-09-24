jq(document).ready( function() {
    // Tracks whether the current submission was triggered by "Save&amp;Print"
    // (as opposed to the plain "Save" button).
    var printAfterSave = false;

    // A plain "Save" must never auto-print, so clear the flag if it is clicked.
    jq('#buttons .submitButton').on('click', function() {
        printAfterSave = false;
    });

    // "Save&amp;Print" performs the normal save, but first records that the form
    // should be printed once we land back on the visit page.
    jq('#save-and-print-button').on('click', function() {
        printAfterSave = true;
        submitHtmlForm();
    });

    // Just before the form is actually submitted, encode the print intent into the
    // return URL. After the encounter is saved, htmlForm.js appends the new
    // encounterId and navigates to this URL (the visit page); the "printForm=true"
    // flag tells the visit page to automatically send the saved form to the printer.
    // We run this on every submission (rather than at click time) so that a
    // re-submit after a validation error still reflects the button last clicked.
    beforeSubmit.push(function() {
        var url = htmlForm.getReturnUrl();
        if (url) {
            // drop any flag left over from a previous attempt so it never accumulates
            url = url.replace(/([?&amp;])printForm=true(&amp;|$)/, function(match, sep, tail) {
                return tail === '&amp;' ? sep : (sep === '?' ? '?' : '');
            });
            if (printAfterSave) {
                url += (url.indexOf('?') === -1 ? '?' : '&amp;') + 'printForm=true';
            }
            htmlForm.setReturnUrl(url);
        }
        return true;
    });
});