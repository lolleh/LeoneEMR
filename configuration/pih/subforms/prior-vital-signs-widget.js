
// This calculates the previous vitals signs captured during this visit
// Used by family planning but could be used elsewhere

(function() {

    const vitalsSignsEncounterType = '2fd151a2-fbef-43e3-b82d-c3f70f1d7333';
    const weightConceptUuid = '3ce93b62-26fe-102b-80cb-0017a47871b2';
    const heightConceptUuid = '3ce93cf2-26fe-102b-80cb-0017a47871b2';
    const systolicBPConceptUuid = '3ce934fa-26fe-102b-80cb-0017a47871b2';
    const systolicBPConceptUuid_second = '55068053-6edf-4887-997a-ba75681ec1a5';
    const diastolicBPConceptUuid = '3ce93694-26fe-102b-80cb-0017a47871b2';
    const diastolicBPConceptUuid_second = 'd710265f-ddd4-4eef-ab18-28113c8328ae';
    const hrConceptUuid = '3ce93824-26fe-102b-80cb-0017a47871b2';
    const temperatureConceptUuid = '3ce939d2-26fe-102b-80cb-0017a47871b2';
    const muacConceptUuid = 'e3e03a93-de7f-41ea-b8f2-60b220b970e9';
    const respiratoryRateConceptUuid = '3ceb11f8-26fe-102b-80cb-0017a47871b2';
    const o2SatConceptUuid = '3ce9401c-26fe-102b-80cb-0017a47871b2';
    const fbgConceptUuid = '160912AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    const fbg2ConceptUuid = '6e291dc0-9dd6-4ccf-bce4-5339c52667a9';
    const rbgConceptUuid = '3cd4e194-26fe-102b-80cb-0017a47871b2';
    const rbg2ConceptUuid = '0e9d36ab-ccfe-4716-9060-ad5f330a28af';

    const contextPath = window.location.href.split('/')[3];
    const apiBaseUrl =  "/" + contextPath + "/ws/rest/v1";
    const monthOption = { month: 'short'};

    const visitUuid = '<lookup expression="encounter.getVisit().getUuid()"/>' ||
        new URLSearchParams(window.location.search).get('visitId');

    jq.getJSON(apiBaseUrl + "/visit/" + visitUuid, {
            v: 'custom:(uuid,id,startDatetime,encounters:(uuid,display,encounterDatetime,encounterType:(uuid,name),obs:(uuid,display,concept:(uuid,display),obsDatetime,value)))'
        },
        function( data ){
            if (data.encounters &amp;&amp; data.encounters.length &gt; 0) {
                for (let index=0; index &lt; data.encounters.length; ++index) {
                    let encounter = data.encounters[index];
                    if (encounter.encounterType.uuid === vitalsSignsEncounterType) {
                        // we found a VitalsSigns encounter on this visit
                        let encounterDate = new Date(encounter.encounterDatetime);
                        let month = new Intl.DateTimeFormat(undefined, monthOption).format(encounterDate);
                        jq("#lastVitalsEncounterDate").text(encounterDate.getDate() + "-" + month + "-" + encounterDate.getFullYear());
                        jq("#lastVitalsEncounterTime").text(encounterDate.toLocaleTimeString());

                        let last_weight = null;
                        let last_height = null;
                        let last_bmi = null;
                        if (encounter.obs &amp;&amp; encounter.obs.length &gt; 0) {
                            jq('#lastVitals').show();
                            for (let j=0; j &lt; encounter.obs.length; ++j) {
                                let obs = encounter.obs[j];
                                if (obs.concept.uuid === systolicBPConceptUuid) {
                                    jq("#last_bp_systolic").text(obs.value);
                                    jq("#last_bp_systolic").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === diastolicBPConceptUuid) {
                                    jq("#last_bp_diastolic").text(obs.value);
                                    jq("#last_bp_diastolic").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === systolicBPConceptUuid_second) {
                                    jq("#last_bp_systolic_second").text(obs.value);
                                    jq("#last_bp_systolic_second").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === diastolicBPConceptUuid_second) {
                                    jq("#last_bp_diastolic_second").text(obs.value);
                                    jq("#last_bp_diastolic_second").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === hrConceptUuid) {
                                    jq("#last_heart_rate").text(obs.value);
                                    jq("#last_heart_rate").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === temperatureConceptUuid) {
                                    jq("#last_temperature_c").text(obs.value);
                                    jq("#last_temperature_c").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === muacConceptUuid) {
                                    jq("#last_muac_mm").text(obs.value);
                                    jq("#last_muac_mm").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === respiratoryRateConceptUuid) {
                                    jq("#last_respiratory_rate").text(obs.value);
                                    jq("#last_respiratory_rate").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === o2SatConceptUuid) {
                                    jq("#last_o2_sat").text(obs.value);
                                    jq("#last_o2_sat").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === weightConceptUuid) {
                                    jq("#last_weight").text(obs.value);
                                    last_weight = obs.value;
                                    jq("#last_weight").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === heightConceptUuid) {
                                    jq("#last_height").text(obs.value);
                                    last_height = obs.value;
                                    jq("#last_height").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === fbgConceptUuid || obs.concept.uuid === fbg2ConceptUuid) {
                                    jq("#last_fbg").text(obs.value);
                                    jq("#last_fbg").removeClass("emptyValue").addClass("value");
                                } else if (obs.concept.uuid === rbgConceptUuid || obs.concept.uuid === rbg2ConceptUuid) {
                                    jq("#last_fbg").text(obs.value);
                                    jq("#last_fbg").removeClass("emptyValue").addClass("value");
                                    jq("#fbg_span").hide();
                                    jq("#rbg_span").show();
                                }
                            }

                            if (last_weight &amp;&amp; last_height) {
                                last_bmi = last_weight / ((last_height/100) * (last_height/100));
                                jq("#last_bmi").text(last_bmi.toFixed(1));
                                jq("#last_bmi").removeClass("emptyValue").addClass("value");
                            }
                            break;
                        }
                    }
                }
            }
        });

})();
