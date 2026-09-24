package org.openmrs.module.pihcore.printer.template;

import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.openmrs.messagesource.MessageSourceService;
import org.openmrs.module.emrapi.EmrApiProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * ZPL template for the patient ID card / ID label.
 *
 * This is a drop-in replacement for the stock pihcore ZplCardTemplate that is
 * swapped into the pihcore module at distro build time (scripts/brand-zpl.sh).
 * It reproduces the upstream layout exactly, adds the MOH + HEAP logos as a
 * ZPL 1-bit graphic band at the top of the card, and shifts the rest of the
 * card down by the logo band so nothing overlaps.
 *
 * The upstream template and its Y-coordinates:
 *   name ^FO220,20    divider ^FO220,100^GB850,0,5
 *   address ^FO220,120 (+50/line)   fields 325 (label) / 365 (value)
 *   divider ^FO220,420  barcode ^FO220,450  id label ^FO500,440
 *   issued on ^FO500,500/540         issued at ^FO840,500/540
 * The patches below add the logo band ending at y~225 and shift every fixed
 * Y coordinate down by SHIFT (235).
 */
@Component("zplCardTemplate")
public class ZplCardTemplate {

    private static final int SHIFT = 235;

    private static int LARGER_FONT_NAME_MAX_SIZE;
    private static int SMALLER_FONT_NAME_MAX_SIZE;

    private final Log log = LogFactory.getLog(getClass());

    @Autowired
    protected MessageSourceService messageSourceService;

    @Autowired
    protected EmrApiProperties emrApiProperties;

    public String generateLabel(Map<String, Object> params) {
        String name = (String) params.get("name");
        String gender = (String) params.get("gender");
        String birthdate = (String) params.get("birthdate");
        Boolean birthdateEstimated = (Boolean) params.get("birthdateEstimated");
        String patientIdentifier = (String) params.get("patientIdentifier");
        List<String> addressLines = params.containsKey("addressLines")
                ? (List<String>) params.get("addressLines") : null;
        String telephoneNumber = params.containsKey("telephoneNumber")
                ? (String) params.get("telephoneNumber") : "";
        String issuingLocation = params.containsKey("issuingLocation")
                ? (String) params.get("issuingLocation") : "";
        String issuedDate = (String) params.get("issuedDate");
        String customCardLabel = params.containsKey("customCardLabel")
                ? (String) params.get("customCardLabel") : "";
        Locale locale = params.containsKey("locale")
                ? (Locale) params.get("locale") : new Locale("ht");

        StringBuilder sb = new StringBuilder();
        sb.append("^XA");
        sb.append("^CI28");
        sb.append("^PW1300");
        sb.append("^MTT");
        sb.append(GeneratedLogos.LOGO_ZPL);

        String font = "V";
        if (StringUtils.isNotBlank(name)) {
            if (name.length() > LARGER_FONT_NAME_MAX_SIZE) {
                font = "U";
            }
            if (name.length() > SMALLER_FONT_NAME_MAX_SIZE) {
                name = StringUtils.substring(name, 0, SMALLER_FONT_NAME_MAX_SIZE);
            }
            sb.append(new StringBuilder().append("^FO220,").append(20 + SHIFT)
                    .append("^A").append(font).append("N^FD").append(name).append("^FS").toString());
        }
        sb.append(new StringBuilder().append("^FO220,").append(100 + SHIFT)
                .append("^GB850,0,5^FS").toString());

        int y = 120 + SHIFT;
        if (addressLines != null && addressLines.size() > 0) {
            for (String line : addressLines) {
                sb.append(new StringBuilder().append("^FO220,").append(y)
                        .append("^ATN^FD").append(line).append("^FS").toString());
                y += 50;
            }
        }

        fieldRow(sb, 220, 325, "coreapps.gender", locale);
        sb.append(new StringBuilder().append("^FO220,").append(365 + SHIFT)
                .append("^ATN^FD").toString());
        if (StringUtils.isNotBlank(gender)) {
            sb.append(messageSourceService.getMessage("coreapps.gender." + gender, null, locale));
        }
        sb.append("^FS");

        String birthdateMessage = birthdateEstimated.booleanValue()
                ? "pihcore.birthdate_estimated" : "pihcore.birthdate";
        fieldRow(sb, 400, 325, birthdateMessage, locale);
        sb.append(new StringBuilder().append("^FO400,").append(365 + SHIFT)
                .append("^ATN^FD").toString());
        if (StringUtils.isNotBlank(birthdate)) {
            sb.append(birthdate);
        }
        sb.append("^FS");

        fieldRow(sb, 740, 325, "ui.i18n.PersonAttributeType.name.14d4f066-15f5-102d-96e4-000c29c2a5d7", locale);
        sb.append(new StringBuilder().append("^FO740,").append(365 + SHIFT)
                .append("^ATN^FD").toString());
        if (StringUtils.isNotBlank(telephoneNumber)) {
            sb.append(telephoneNumber);
        }
        sb.append("^FS");

        sb.append(new StringBuilder().append("^FO220,").append(420 + SHIFT)
                .append("^GB850,0,5^FS").toString());
        sb.append(new StringBuilder().append("^FO220,").append(450 + SHIFT)
                .append("^ATN^BY2,2,10^BCN,100,Y^FD").append(patientIdentifier).append("^FS").toString());
        sb.append(new StringBuilder().append("^FO500,").append(440 + SHIFT)
                .append("^ATN^FD").append(customCardLabel).append("^FS").toString());

        fieldRow(sb, 500, 500, "pihcore.idcard.issuedOn", locale);
        sb.append(new StringBuilder().append("^FO500,").append(540 + SHIFT)
                .append("^ATN^FD").append(issuedDate).append("^FS").toString());

        fieldRow(sb, 840, 500, "pihcore.idcard.issuedAt", locale);
        sb.append(new StringBuilder().append("^FO840,").append(540 + SHIFT)
                .append("^ATN^FD").append(issuingLocation).append("^FS").toString());

        sb.append("^XZ");
        return sb.toString();
    }

    private void fieldRow(StringBuilder sb, int x, int y, String messageCode, Locale locale) {
        sb.append(new StringBuilder().append("^FO").append(x).append(",")
                .append(y + SHIFT).append("^ASN^FD")
                .append(messageSourceService.getMessage(messageCode, null, locale))
                .append("^FS").toString());
    }

    public String getEncoding() {
        return "UTF-8";
    }

    static {
        LARGER_FONT_NAME_MAX_SIZE = 26;
        SMALLER_FONT_NAME_MAX_SIZE = 35;
    }
}