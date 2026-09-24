jq(document).ready( function() {

    <ifMode mode="VIEW" include="true">
        //In the view mode we want to make sure that the paragraphs are on separate lines
        const paragraphs = jq('#rapid-tests-widget p').css('display', 'block');
    </ifMode>

});