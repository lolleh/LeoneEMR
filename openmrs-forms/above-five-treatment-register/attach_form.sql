INSERT INTO openmrs.htmlformentry_html_form
  (form_id, name, xml_data, creator, date_created, changed_by, date_changed, retired, uuid, description)
VALUES
  (6, NULL, '<!--
  ABOVE FIVE (GENERAL) TREATMENT REGISTER — OpenMRS HTML FormEntry

  STATUS:                      (DRAFT for testing — not yet imported)
  ENCOUNTER TYPE:              Visit Note (encounter_type_id=3)
  OPENMRS DISTRO:              openmrs-reference-application-distro:demo

  CONCEPT STRATEGY
  ---------------
  All conceptId references below are REAL OpenMRS concept UUIDs that have been
  created in this demo instance (see create_concepts.py and concept-uuids*.json).
  Morbidity conditions are Boolean concepts rendered as checkboxes; when ticked
  the patient "has" the condition.

  115 concepts were created via the OpenMRS REST API on 2026-08-29
  (101 condition/morbidity + 14 identifier); 2 facility fields were later removed
  and purged, leaving 113 in use.
  A few conditions re-use pre-existing dictionary concepts (Leprosy, Dental
  caries, Malaria, Anaemia, etc.) by exact name match — see CONCEPT_MAPPING.md.

  Demographic fields (occupation, marital status, address, NIN) are kept as
  encounter obs here for a self-contained, testable form. In production these
  are better modelled as person attributes.

  See: CONCEPT_MAPPING.md for the full table.
-->
<htmlform formUuid="eaad2f41-de8f-48b7-9d40-50187fb95932" formName="Above Five (General) Treatment Register" formEncounterType="d7151f82-c1f3-4152-a605-2f9ea7414a79" formVersion="1.0">

<style>
  fieldset { margin-bottom: 16px; border: 1px solid #ccc; border-radius: 6px; padding: 10px 14px; }
  legend { font-weight: bold; padding: 0 6px; }
  .sect-title { font-weight: bold; margin: 12px 0 6px; }
  table.tbl { width: 100%; border-collapse: collapse; }
  table.tbl td, table.tbl th { border: 1px solid #ccc; padding: 4px 6px; font-size: 13px; }
</style>

<fieldset>
  <legend>Facility / Visit</legend>
  <label>Ownership</label> <obs conceptId="b891e640-5fe6-4833-9a20-f52c980c4505"/>
  <label>Service point</label> <obs conceptId="fb953d82-5042-41c0-ba7b-cab46e34dc5e"/>
</fieldset>

<fieldset>
  <legend>Patient &amp; Visit Details</legend>
  <label>Registration number</label> <obs conceptId="7657df04-2037-4fa8-a023-1d96b9c2ff65"/>
  <label>Date seen</label> <encounterDate/>
  <label>Date of onset</label> <obs conceptId="41851ab2-7dc9-4530-897a-b90a1fc60517"/>
  <label>NIN</label> <obs conceptId="222c6b93-2bf4-413f-a654-5676181cd07a"/>
  <label>Type of visit</label> <obs conceptId="1515414d-5e68-42ef-a239-34c86e494679" style="radio"/>
  <label>Category of patient</label> <obs conceptId="1ce41cb6-3aca-424d-8545-5d7b56d8a343" style="radio"/>
  <label>Provider</label> <encounterProvider/>
</fieldset>

<!-- ============================ MALARIA ============================ -->
<fieldset>
  <legend>Malaria</legend>
  <label>Treated with ACT &lt;24h / &gt;24h / without ACT, etc.:</label>
  <table class="tbl">
    <tr>
      <td>Fever cases (suspected malaria)</td><td><obs conceptId="6b1b7255-4bdf-4c9d-b411-314de1c11f9a" style="checkbox"/></td>
      <td>RDT positive</td><td><obs conceptId="128b88e4-49cd-4a8f-85b3-de536741cd54" style="checkbox"/></td>
    </tr>
    <tr>
      <td>RDT negative</td><td><obs conceptId="82752b4b-940a-462a-869a-d34e5f3c90b6" style="checkbox"/></td>
      <td>Microscopy positive</td><td><obs conceptId="31505342-ed59-4253-841f-43e8718467ca" style="checkbox"/></td>
    </tr>
    <tr>
      <td>Microscopy negative</td><td><obs conceptId="953a35a2-c6f7-4977-a3da-7efa7e31e74e" style="checkbox"/></td>
      <td>Treated with ACT &lt;24h</td><td><obs conceptId="ada12301-be11-4a63-9eb5-2a9d9b6e18de" style="checkbox"/></td>
    </tr>
    <tr>
      <td>Treated with ACT &gt;24h</td><td><obs conceptId="da4dc155-856a-456e-bd82-4430d876bd35" style="checkbox"/></td>
      <td>Treated without ACT</td><td><obs conceptId="da85de75-b82d-4548-aa58-a9cf187dcfac" style="checkbox"/></td>
    </tr>
    <tr>
      <td>Artesunate injection</td><td><obs conceptId="85ba420b-17be-4f94-90a6-c253913cae93" style="checkbox"/></td>
      <td>Severe malaria (Artesunate IV/IM &amp; Supp)</td><td><obs conceptId="da58522b-8e66-426f-9787-3d909918db56" style="checkbox"/></td>
    </tr>
    <tr>
      <td>Parenteral anti-malarial</td><td><obs conceptId="9965b265-a15f-4150-887c-ed73fbe879fe" style="checkbox"/></td>
      <td></td><td></td>
    </tr>
  </table>
</fieldset>

<!-- ============================ EYE ============================ -->
<fieldset>
  <legend>Eye</legend>
  <label>Eye infection</label> <obs conceptId="3c960886-9501-4466-950a-5a6e30ac9034" style="checkbox"/>
  <label>Eye condition (all types, except infection)</label> <obs conceptId="217b71b7-d457-47e9-9f29-9f34f75c1be8" style="checkbox"/>
</fieldset>

<!-- ============================ INFECTIOUS ============================ -->
<fieldset>
  <legend>Infectious Diseases</legend>
  <div class="sect-title">Malnutrition</div>
  <label>Moderate malnutrition</label> <obs conceptId="50befc52-ebdc-44a8-92be-bb62eb0019ed" style="checkbox"/>
  <label>Severe malnutrition</label> <obs conceptId="6b4685fe-b5f9-4634-8124-80045d9e269f" style="checkbox"/>

  <div class="sect-title">Notifiable Medical Conditions (eIDSR / eCBDS)</div>
  <label>AFP</label> <obs conceptId="9244f9b0-63e5-4dd9-a995-726214965b40" style="checkbox"/>
  <label>AVHF</label> <obs conceptId="78158612-4c10-4f2a-b7d5-d13c849c9bbf" style="checkbox"/>
  <label>Cholera</label> <obs conceptId="122604AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Dysentery (bloody diarrhoea)</label> <obs conceptId="5abb022f-406a-4ee6-a223-abf11a944ca1" style="checkbox"/>
  <label>Measles</label> <obs conceptId="134561AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Rubella</label> <obs conceptId="933872e1-c068-44d9-a0be-96b465327402" style="checkbox"/>
  <label>Meningitis / Encephalitis</label> <obs conceptId="115835AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Buruli ulcer</label> <obs conceptId="cba00176-dd4a-4024-b2a7-025680d7c621" style="checkbox"/>
  <label>Yellow fever</label> <obs conceptId="9aafdba1-62ac-4e27-8637-28ee98548dcf" style="checkbox"/>
  <label>Typhoid / Paratyphoid</label> <obs conceptId="a9796b0e-6e33-4bf9-a2bd-5c7b0524f0f3" style="checkbox"/>
  <label>Tetanus</label> <obs conceptId="124957AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Animal bites</label> <obs conceptId="e5eeb46b-2e38-4de8-a8b8-511321173de8" style="checkbox"/>

  <div class="sect-title">Other infectious</div>
  <label>AIDS</label> <obs conceptId="b60b9d4d-718a-4180-8773-741876da2755" style="checkbox"/>
  <label>Pneumonia with antibiotic</label> <obs conceptId="fe5cd35c-22c3-4af5-82bd-bbbc6763aa58" style="checkbox"/>
  <label>Pneumonia without antibiotic</label> <obs conceptId="6a30671e-c024-4559-bef5-bf71a80efc14" style="checkbox"/>
  <label>Pneumonia treated in facility</label> <obs conceptId="25a05262-2c2c-485a-9d0a-2c5e3cb9efdc" style="checkbox"/>
  <label>Chicken pox</label> <obs conceptId="7d7c330f-12b1-4f1f-b379-3d4fb148f456" style="checkbox"/>
  <label>Watery diarrhoea (ORS + Zinc)</label> <obs conceptId="6ace0b14-465e-44a9-97ce-350c40a52989" style="checkbox"/>
  <label>Watery diarrhoea (ORS only)</label> <obs conceptId="29d49454-9cf6-43d1-8abe-7e37d065be54" style="checkbox"/>
  <label>Hepatitis (all types)</label> <obs conceptId="474bb6aa-d3dd-4080-a9d3-438ea418ec67" style="checkbox"/>
  <label>Leprosy</label> <obs conceptId="116344AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Severe pneumonia (oxygen therapy)</label> <obs conceptId="9fd4090c-4f22-4b8a-9b17-25709cadc78b" style="checkbox"/>
  <label>Diarrhoea with severe dehydration (IV RL)</label> <obs conceptId="362c147d-3215-4043-8775-51348506000d" style="checkbox"/>
  <label>Mumps</label> <obs conceptId="7ba8bd22-c70e-4914-8ea4-0758bd1b8e4d" style="checkbox"/>
  <label>Sepsis</label> <obs conceptId="31f9e711-6b25-4fda-adb4-8e19aa00e2df" style="checkbox"/>
  <label>Skin infection</label> <obs conceptId="510440a3-e05e-49d0-a833-0768740de721" style="checkbox"/>
  <label>PID</label> <obs conceptId="f55df4ef-1b86-42f9-bbd8-66913a7ab74e" style="checkbox"/>
  <label>Genital discharge</label> <obs conceptId="e0eb290f-7b4f-40cd-bc91-e8cdd0d5aadd" style="checkbox"/>
  <label>Genital ulcer</label> <obs conceptId="bee47d56-cbe0-47f2-a6fa-f2f867a9ce7e" style="checkbox"/>
  <label>Tuberculosis (TB)</label> <obs conceptId="160156AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>UTI</label> <obs conceptId="70d4fd36-cb4e-46a9-937f-0ef35ba4070c" style="checkbox"/>
  <label>Onchocerciasis</label> <obs conceptId="e07eaa27-172c-4f82-906f-33cea93a57e8" style="checkbox"/>
  <label>Schistosomiasis</label> <obs conceptId="117152AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Trachoma</label> <obs conceptId="112287AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Other infectious conditions</label> <obs conceptId="fb417656-f2c3-4ee7-83b2-b7dc6e5bf11b" style="checkbox"/>
  <label>Adverse drug reaction</label> <obs conceptId="a7f21431-5d05-483f-bc73-6b88b4413674" style="checkbox"/>
</fieldset>

<!-- ========== INTERNAL MEDICINE, NCD & MENTAL ========== -->
<fieldset>
  <legend>Internal Medicine, NCD &amp; Mental</legend>
  <label>Anaemia</label> <obs conceptId="121629AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Asthma</label> <obs conceptId="121375AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Sickle cell disease</label> <obs conceptId="f2b662e3-ce14-4d22-af0f-02a4e53a5f9f" style="checkbox"/>
  <label>Cancer (all types)</label> <obs conceptId="e9468fa0-641c-443d-8648-cce2f2edcbd5" style="checkbox"/>
  <label>Liver disease</label> <obs conceptId="fb9c870c-10e3-4095-acaf-70ffa4e7b5f2" style="checkbox"/>
  <label>Cardiovascular disease (all types)</label> <obs conceptId="5a66a22a-19df-41b7-8074-494255823bd4" style="checkbox"/>
  <label>Chronic respiratory disease</label> <obs conceptId="94ae30bc-c3fa-4504-887a-8f4e7a773452" style="checkbox"/>
  <label>Diabetes (Type 1 or 2)</label> <obs conceptId="119481AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Epilepsy</label> <obs conceptId="155AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Hypertension</label> <obs conceptId="117399AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Upper GI / Pancreatitis</label> <obs conceptId="60214245-c173-4a64-a00b-82e1bc801e97" style="checkbox"/>
  <label>Chronic liver / Cirrhosis</label> <obs conceptId="62cab07d-026f-4992-8307-bbd24cc9dc32" style="checkbox"/>
  <label>Appendicitis</label> <obs conceptId="28b0f52a-3c67-49f5-a633-814680e4cc43" style="checkbox"/>
  <label>Ileus</label> <obs conceptId="0b91a7b8-fa77-495c-8dbd-83e2dba0022c" style="checkbox"/>
  <label>Obstruction</label> <obs conceptId="3aaae386-ca7a-4a41-8fd2-163b339641df" style="checkbox"/>
  <label>Stroke</label> <obs conceptId="d5c1995e-aaf9-4e46-87ab-a905f4bd32e1" style="checkbox"/>
  <label>Heart failure</label> <obs conceptId="fa1bc75b-f257-4da8-a68b-8e72e17e6387" style="checkbox"/>
  <label>Kidney disorders</label> <obs conceptId="23edac37-c75e-415b-a7d9-760906840ad2" style="checkbox"/>
  <label>Mental disorder (all types)</label> <obs conceptId="f1a68e2a-1913-449c-a9d9-6af815bc0ef8" style="checkbox"/>
  <label>Other NCD conditions</label> <obs conceptId="fb3f5ff6-f782-478b-9c1d-509291a6940b" style="checkbox"/>
</fieldset>

<!-- ========== SUSPECTED CANCER ========== -->
<fieldset>
  <legend>Suspected Cancer</legend>
  <label>Breast</label> <obs conceptId="9c3b6256-5d3c-4a75-90d5-17b1be6da6f2" style="checkbox"/>
  <label>Prostate</label> <obs conceptId="93b5bf5b-0dae-4f3e-b120-b3f8a8c90365" style="checkbox"/>
  <label>Cervical</label> <obs conceptId="38be7097-2b04-4df1-80ec-9838750333ff" style="checkbox"/>
  <label>Childhood</label> <obs conceptId="31005895-68de-4c61-a1e9-3b50f7d12200" style="checkbox"/>
  <label>Lungs</label> <obs conceptId="9b32e470-e11e-4af0-bbc8-12187a288626" style="checkbox"/>
  <label>Liver</label> <obs conceptId="66c6cacd-fe9a-4bbc-870b-97c3bc8cba61" style="checkbox"/>
  <label>Others</label> <obs conceptId="92fb8200-5f8d-43e3-b8cf-99693bf7305b" style="checkbox"/>
</fieldset>

<!-- ========== SUSPECTED AVHL / F & D ========== -->
<fieldset>
  <legend>Suspected AVHL / Febrile &amp; other</legend>
  <label>Lassa fever</label> <obs conceptId="97aa194b-ff8c-440f-bf5e-7def7cb64518" style="checkbox"/>
  <label>Marburg</label> <obs conceptId="8cf7feff-81b6-4389-a388-ecffc98910f4" style="checkbox"/>
  <label>Yellow fever</label> <obs conceptId="9aafdba1-62ac-4e27-8637-28ee98548dcf" style="checkbox"/>
  <label>Others</label> <obs conceptId="a6cf24da-b177-4dc4-b51e-df55dc0c5867" style="checkbox"/>
  <label>Suspected MPOX</label> <obs conceptId="937f42eb-57b4-43c5-aecf-a3037d4f17e5" style="checkbox"/>
  <label>Ebola</label> <obs conceptId="0f73b0aa-1ef3-4011-acc5-48d6ab3b1f93" style="checkbox"/>
  <label>Severe malaria</label> <obs conceptId="160155AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>PPH &amp; APH</label> <obs conceptId="bce9f424-230a-45e0-8ae0-0f75166a3f5a" style="checkbox"/>
  <label>Worm infestation</label> <obs conceptId="44ec868f-d821-4735-a896-b302fc0ec361" style="checkbox"/>
  <label>Chronic diseases</label> <obs conceptId="13bc6a79-0fb9-49e9-bd80-82ef9f008b19" style="checkbox"/>
</fieldset>

<!-- ========== ANAEMIA ========== -->
<fieldset>
  <legend>Anaemia</legend>
  <!-- confirm grouping: source register groups these under ANAEMIA -->
  <label>Severe malaria</label> <obs conceptId="160155AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>PPH &amp; APH</label> <obs conceptId="bce9f424-230a-45e0-8ae0-0f75166a3f5a" style="checkbox"/>
  <label>Worm infestation</label> <obs conceptId="44ec868f-d821-4735-a896-b302fc0ec361" style="checkbox"/>
  <label>Chronic diseases</label> <obs conceptId="13bc6a79-0fb9-49e9-bd80-82ef9f008b19" style="checkbox"/>
</fieldset>

<!-- ========== DENTAL ========== -->
<fieldset>
  <legend>Dental Condition</legend>
  <label>Caries</label> <obs conceptId="119558AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" style="checkbox"/>
  <label>Abscess</label> <obs conceptId="263225d8-cd15-442e-8cbe-20ab134c96e8" style="checkbox"/>
  <label>Fracture</label> <obs conceptId="e669cbc5-76db-4199-88c2-753ffab30e41" style="checkbox"/>
</fieldset>

<!-- ========== SUSPECTED POISON ========== -->
<fieldset>
  <legend>Suspected Poison</legend>
  <label>Food</label> <obs conceptId="10a4989f-e553-4235-ab02-dd1c0aa1bbe8" style="checkbox"/>
  <label>Caustic soda</label> <obs conceptId="7d538977-821a-4ac0-8d6d-25c4db7aafcc" style="checkbox"/>
  <label>Others</label> <obs conceptId="39e47f61-3985-4539-b63e-c301612738a5" style="checkbox"/>
</fieldset>

<!-- ========== DIARRHOEA ========== -->
<fieldset>
  <legend>Diarrhoea</legend>
  <label>With blood — ORS &amp; Zinc</label> <obs conceptId="c25f1dd8-68ee-4c15-9649-53b889e0bd14" style="checkbox"/>
  <label>Without blood — ORS &amp; Zinc</label> <obs conceptId="8170cef7-592d-4f3e-85b2-adc92c9694b2" style="checkbox"/>
  <label>With severe dehydration</label> <obs conceptId="1cb4c57d-9136-4409-9b7d-7bd1e45248d2" style="checkbox"/>
</fieldset>

<!-- ========== DISABILITY ========== -->
<fieldset>
  <legend>Disability</legend>
  <label>Physical</label> <obs conceptId="b382d354-d394-42d7-a629-1df356642c51" style="checkbox"/>
  <label>Visual impairment</label> <obs conceptId="18d7e813-dc2b-4d1f-802e-cde9fe2aa13a" style="checkbox"/>
  <label>Hearing impairment</label> <obs conceptId="c3ab3553-0e5b-4342-b9cf-83968974f36c" style="checkbox"/>
  <label>Speech and language</label> <obs conceptId="3afa12ff-79aa-41d0-81a9-0cdfc22612a0" style="checkbox"/>
  <label>Multiple</label> <obs conceptId="1ff094d8-973a-4b58-9b94-f6bbc1f92169" style="checkbox"/>
  <label>Intellectual</label> <obs conceptId="7a4b0fb2-d87e-46c6-92ae-5a84656366dd" style="checkbox"/>
</fieldset>

<!-- ========== SURGICAL ========== -->
<fieldset>
  <legend>Surgical</legend>
  <label>Acute abdomen</label> <obs conceptId="3a482da7-d298-40da-a43d-9ad2f6c74683" style="checkbox"/>
  <label>Appendicitis</label> <obs conceptId="28b0f52a-3c67-49f5-a633-814680e4cc43" style="checkbox"/>
  <label>ENT disorder</label> <obs conceptId="8efe44ba-8f63-4198-9694-95b4a4c48d60" style="checkbox"/>
  <label>Hernia</label> <obs conceptId="24cb46b7-d971-4d94-9cd1-9a5d4f4037f1" style="checkbox"/>
  <label>Hydrocele</label> <obs conceptId="05bd7b50-666d-4722-b29a-c6f55d819c0d" style="checkbox"/>
  <label>Lymphoedema</label> <obs conceptId="6332df1f-fa74-4ea0-a4d7-3bf934f22ec4" style="checkbox"/>
  <label>Oral &amp; dental conditions</label> <obs conceptId="cc7139f8-83e1-420c-8079-954fdd57e0c5" style="checkbox"/>
  <label>PUD</label> <obs conceptId="51a97df0-cbdb-462d-98a7-dda3e326555f" style="checkbox"/>
  <label>Wounds/Trauma — RTA</label> <obs conceptId="b3f91afa-0551-4cb1-a7bd-e2d1ec9afcc8" style="checkbox"/>
  <label>Wounds/Trauma — Non-RTA</label> <obs conceptId="9dbd12ef-9ce3-41c5-aee5-208d22e7a393" style="checkbox"/>
  <label>Burns</label> <obs conceptId="c2861101-2405-42fe-b826-5806c96d9a8b" style="checkbox"/>
  <label>Typhoid perforation</label> <obs conceptId="7d0b12c4-b7fe-4233-a1a6-f3455bf0fb9c" style="checkbox"/>
  <label>Haemorrhoids / Piles</label> <obs conceptId="0fdb2054-695f-4495-8187-3d9e4d26a5e2" style="checkbox"/>
  <label>Other surgical conditions</label> <obs conceptId="afe6d69f-4ece-40cf-bf89-52990016d8ab" style="checkbox"/>
</fieldset>

<!-- ========== ALL OTHER MORBIDITIES ========== -->
<fieldset>
  <legend>All Other Morbidities</legend>
  <label>Other condition / notes</label> <obs conceptId="d03e30ca-e9d8-4511-8dca-7b8588ee5cea" style="textarea"/>
</fieldset>

</htmlform>
', 1, '2026-08-29 19:35:18', NULL, NULL, 0, '64460500-7d80-45bd-bc29-94776e199e0e', 'Above Five (General) Treatment Register');
