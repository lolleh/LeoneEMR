package org.openmrs.module.pihreporting;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.openmrs.module.BaseModuleActivator;

public class PihReportingActivator extends BaseModuleActivator {

    private final Log log = LogFactory.getLog(getClass());

    @Override
    public void started() {
        log.info("PHU360 Reporting module started");
    }

    @Override
    public void stopped() {
        log.info("PHU360 Reporting module stopped");
    }
}