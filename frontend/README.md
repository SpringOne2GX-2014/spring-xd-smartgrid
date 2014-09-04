Introduction
------------

The Smartgrid-Frontend is a Spring Boot app that hosts a D3.js visualization of smartplug load distribution 
as well as the actual and predicted energy consumption by house. 
It accesses data from aggregate-counters via the REST interface provided by Spring XD.

Screenshot:
![ui](/frontend/ui.png)


Preparation
------------
Download agg_load_min_by_h_hh_p.csv: (90mb)
https://drive.google.com/a/pivotal.io/file/d/0Bzyuv7p_xXJJcm92Zl9wTWFVWDQ/edit?usp=sharing

Format: id, timestamp, value, property, plug_id, household_id, house_id
This file contains aggregated load measurements (property = 1) only.
Data is averaged by minute (average load values per plug, household, house).


Stream definition
-----------------

Format for aggregate counters
> 'smartgrid_h_'+payload.house_id+'_load_actual'
e.g:
> smartgrid_h_0_load_actual
> smartgrid_h_13_load_actual
> smartgrid_h_28_load_actual


start xd-singlenode
start xd-shell

```
stream create smartgrid_ingestion --definition "http | file" --deploy

stream create smartgrid_load_timeseries_actual --definition "tap:stream:smartgrid_ingestion > aggregate-counter --timeField=payload.dateTime.toString() --incrementExpression=(T(java.lang.Double).parseDouble(payload.value.toString()))/60 --nameExpression='smartgrid_h_'+payload.house+'_load_actual'" --deploy

stream create smartgrid_load_timeseries_predicted --definition "tap:stream:smartgrid_ingestion >  analytic-pmml --inputType=application/x-xd-tuple --location=/tmp/nn.pmml --inputFieldMapping='ts:timestamp,house:house' | aggregate-counter --timeField=payload.dateTime.toString() --incrementExpression=T(java.lang.Double).parseDouble(payload.FinalResult.toString())/60 --nameExpression='smartgrid_h_'+payload.house+'_load_predicted'" --deploy
```                           

To speed up the ingestion one could replace the `log` sink with a `null` sink that looks like this:
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:int="http://www.springframework.org/schema/integration"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
		http://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.springframework.org/schema/integration
		http://www.springframework.org/schema/integration/spring-integration.xsd">

    <int:channel id="input"/>

    <int:bridge input-channel="input" output-channel="nullChannel"/>
</beans>
```
                        
The aggregate-counters are named after the scheme:
> 'smartgrid_h_'+payload.house_id+'_load_actual'
> 'smartgrid_h_'+payload.house_id+'_load_predicted'

They will automatically picked up from the visualization app.

Populate aggregate counters in XD
---------------------------------

Start Apache JMeter

Open jmeter testplan:
load_testing/SmartGrid.jmx

Configure the CSV file to use under:

> Test Plan -> Thread Group -> While Controller -> CSV Data Set Config -> Filename: enter path to agg_load_min_by_h_hh_p.csv

If jmeter was started in the directory where agg_load_min_by_h_hh_p.csv is located then the sole filename is enough.

Start the test plan by clicking on the the green "play" button.

In XD-Shell display the counter: 
>aggregate-counter display --name smartgrid_h_28_load_actual --from '2013-09-01 00:00:00' --to '2013-09-02 00:00:00' --resolution hour

```
xd:>aggregate-counter display --name smartgrid_h_28_load_actual --from '2013-09-01 00:00:00' --to '2013-09-02 00:00:00' --resolution hour
  AggregateCounter=smartgrid_h_28_load_actual
  -------------------------------------------  -  ------
  TIME                                         -  COUNT
  Sun Sep 01 00:00:00 CEST 2013                |  32,684
  Sun Sep 01 01:00:00 CEST 2013                |  0
  Sun Sep 01 02:00:00 CEST 2013                |  0
```

To start the smartgrid-frontend app goto the springxd-smartgrid-demo/smartgrid-frontend directory and start the
Spring boot app via:

> mvn spring-boot:run

The frontend is available at http://localhost:8080

You can customize the location of the Spring XD Aggregate Counter URL via 

> -Dsmartgrid.frontend.aggregateCounterUrl=http://localhost:9393/metrics/aggregate-counters