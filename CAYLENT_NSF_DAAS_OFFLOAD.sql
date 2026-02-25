use role developer_npe;
use warehouse developer_wh_qas;
use database nsf_daas_prd;
use schema data;

create or replace temp stage offload;

create
or replace temp table temp_orders as (
    select
        ACCESSION_HUB_ID,
        --ACCESSION_SRC_ID,
        CASE_HUB_ID,
        --CASE_SRC_ID,
        --CASE_NO,
        TEST_ORDER_HUB_ID,
        --TEST_ORDER_SRC_ID,
        GENE_NAME,
        ANALYSIS_PERFORMED,
        PANEL_CODE,
        PANEL_NAME,
        TEST_CODE,
        TEST_NAME,
        EXCLUSION_REASONS,
        ORDERING_DOCTOR_HUB_ID,
        TREATING_DOCTOR_HUB_ID,
        PATIENT_HUB_ID,
        CLIENT_HUB_ID,
        TEST_ORDER_STATUS,
        TECHNOLOGY_NAME,
        TECHNOLOGY_STD,
        TECHNIQUE,
        RESULT_LEVEL,
        RESULT_VALUE,
        RESULT_VALUE_STANDARD,
        RESULT_STATUS,
        NUCLEOTIDE_CHANGE,
        AMINO_ACID_CHANGE,
        FUSION_GENE_PARTNERS,
        VARIANT_CLASSIFICATION,
        VARIANT_TYPE,
        HGVSC,
        HGVSP,
        AMINO_ACIDS,
        VARIANT_CONSEQUENCE,
        MUTANT_ALLELE_FREQUENCY,
        VARIANT_LOCATION,
        VARIANT_LOCATION_ORDINAL,
        KARYOTYPE,
        TEST_ORDERED_TIMESTAMP,
        CASE_FIRST_SIGNED_TIMESTAMP,
        --CASE_LAST_SIGNED_TIMESTAMP,
        --IS_STP,
        --ORDERS_FACT_COMPOSITE_ID,
        TEST_INFO_EXISTS
    from
        nsf_daas_prd.data.orders_fact
    where
        1 = 1
        and exclusion_reasons is null
        and CASE_FIRST_SIGNED_TIMESTAMP between '2024-06-01'
        and '2025-05-31'
);


--set ordersfactname = 'ORDERS_FACT_DATA_' || TO_VARCHAR(CURRENT_DATE);

COPY INTO @offload/ORDERS_FACT_DATA_20250609
FROM temp_orders
 	FILE_FORMAT = (   TYPE = CSV
			, FIELD_DELIMITER='|'
			, FILE_EXTENSION = '.CSV'
			, NULL_IF = ('')
			, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
			, COMPRESSION=NONE
			, EMPTY_FIELD_AS_NULL = FALSE
			, TRIM_SPACE = TRUE
		      ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;

--select * from temp_orders;

--set clientsname = 'CLIENT_DATA_' || TO_VARCHAR(CURRENT_DATE);

COPY INTO @offload/CLIENT_DATA_20250609
FROM (
	select distinct
    cld.CLIENT_HUB_ID,
    --    CLIENT_SRC_ID,
    CLIENT_NUMBER,
    CLIENT_NAME,
    --    CLIENT_ADDR1,
    --    CLIENT_CITY,
    CLIENT_STATE,
    CLIENT_STATE_CODE,
    CLIENT_POSTAL_CODE,
    CLIENT_COUNTRY,
    CLIENT_COUNTRY_CODE,
    --   CLIENT_LATITUDE,
    --   CLIENT_LONGITUDE,
    --    CLIENT_PHONE,
    CLIENT_TYPE,
    CLIENT_SPECIALTY,
    --    CLIENT_IS_OPT_OUT,
    CLIENT_SETTING
from
    nsf_daas_prd.data.client_dim cld
    join temp_orders ta on cld.client_hub_id = ta.client_hub_id
	)
 	FILE_FORMAT = (   TYPE = CSV
			, FIELD_DELIMITER='|'
			, FILE_EXTENSION = '.CSV'
			, NULL_IF = ('')
			, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
			, COMPRESSION=NONE
			, EMPTY_FIELD_AS_NULL = FALSE
			, TRIM_SPACE = TRUE
		      ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;

COPY INTO @offload/DOCTOR_DATA_20250609
FROM (   
	select distinct
    od.DOCTOR_HUB_ID,
    --    DOCTOR_SRC_ID,
    --    PROVIDER_UNIQUE_ID,
    --    PROVIDER_FIRST_NAME,
    --    PROVIDER_MIDDLE_NAME,
    --    PROVIDER_LAST_NAME,
    --    PROVIDER_FULL_NAME,
    NPI,
    PROVIDER_GROUP,
    PROVIDER_CLASSIFICATION,
    PROVIDER_SPECIALIZATION,
    PROVIDER_TYPE,
    --    PRACTICE_LOCATION_ADDR1,
    --    PRACTICE_LOCATION_ADDR2,
    --    PRACTICE_LOCATION_CITY,
    PRACTICE_LOCATION_STATE,
    PRACTICE_LOCATION_POSTAL_CODE,
    PRACTICE_LOCATION_COUNTRY,
    PRACTICE_LOCATION_COUNTRY_CODE --,
    --    OPT_OUT
from
    nsf_daas_prd.data.doctor_dim od
    join temp_orders ta on od.doctor_hub_id = ta.ORDERING_DOCTOR_HUB_ID
UNION
select distinct
    td.DOCTOR_HUB_ID,
    --    DOCTOR_SRC_ID,
    --    PROVIDER_UNIQUE_ID,
    --    PROVIDER_FIRST_NAME,
    --    PROVIDER_MIDDLE_NAME,
    --    PROVIDER_LAST_NAME,
    --    PROVIDER_FULL_NAME,
    NPI,
    PROVIDER_GROUP,
    PROVIDER_CLASSIFICATION,
    PROVIDER_SPECIALIZATION,
    PROVIDER_TYPE,
    --    PRACTICE_LOCATION_ADDR1,
    --    PRACTICE_LOCATION_ADDR2,
    --    PRACTICE_LOCATION_CITY,
    PRACTICE_LOCATION_STATE,
    PRACTICE_LOCATION_POSTAL_CODE,
    PRACTICE_LOCATION_COUNTRY,
    PRACTICE_LOCATION_COUNTRY_CODE --,
    --    OPT_OUT
from
    nsf_daas_prd.data.doctor_dim td
    join temp_orders ta on td.doctor_hub_id = ta.TREATING_DOCTOR_HUB_ID
	)
FILE_FORMAT = (   TYPE = CSV
		, FIELD_DELIMITER='|'
		, FILE_EXTENSION = '.CSV'
		, NULL_IF = ('')
		, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
		, COMPRESSION=NONE
		, EMPTY_FIELD_AS_NULL = FALSE
		, TRIM_SPACE = TRUE
		  ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;

COPY INTO @offload/ACCESSION_DATA_20250609
FROM (      
select distinct
    a.ACCESSION_HUB_ID,
--    ACCESSION_SRC_ID,
--    ACCESSION_CREATED_TIMESTAMP,
--    ACCESSION_EXCLUSION_REASONS,
    ICD_CODES,
    COHORT_CODES,
    DISEASE_STAGE_NAME,
    DISEASE_TYPE_NAME,
    REASON_FOR_REFERRAL,
    DISEASE_STATUS_NAME,
--    IS_ONLINE_ORDER,
--    IS_FLORIDA_ORDER,
    PATIENT_AGE_AT_TIME_OF_SERVICE
from
    nsf_daas_prd.data.accession_dim a
    join temp_orders ta on a.accession_hub_id = ta.accession_hub_id
	)
FILE_FORMAT = (   TYPE = CSV
		, FIELD_DELIMITER='|'
		, FILE_EXTENSION = '.CSV'
		, NULL_IF = ('')
		, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
		, COMPRESSION=NONE
		, EMPTY_FIELD_AS_NULL = FALSE
		, TRIM_SPACE = TRUE
		  ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;
 
COPY INTO @offload/CASE_DATA_20250609
FROM (  
	select distinct
    c.CASE_HUB_ID,
--    CASE_SRC_ID,
--    CASE_NO,
--    CASE_CREATED_TIMESTAMP,
--    CASE_FIRST_SIGNED_TIMESTAMP,
--    CASE_LAST_SIGNED_TIMESTAMP,
    SERVICE_LEVEL_NAME,
    CASE_CURRENT_WORKFLOW_STEP,
    CASE_TYPE_NAME,
    DESIGNATOR_CODE,
    c.TECHNOLOGY_NAME,
    CASE_BODY_SITE_NAMES,
    CASE_BODY_SITE_NAMES_STANDARD,
    CASE_SPECIMEN_TYPE_NAMES,
    CASE_SPECIMEN_TYPE_CATEGORIES,
    CASE_SPECIMEN_TRANSPORT_NAMES,
--    CASE_SPECIMEN_NAMES,
--    CASE_EXTERNAL_SPECIMEN_IDS,
--    CASE_INTERNAL_SPECIMEN_IDS,
--    CASE_COLLECTION_DATE,
    CASE_PANEL_CODES,
    CASE_PANEL_NAMES,
    CASE_OVERALL_RESULT,
    CASE_INTERPRETATION,
--    KARYOTYPE,
    CASE_TEST_NAMES--,
--    CASE_EXCLUSION_REASONS,
--    RESULT_EXCLUSION_REASON
from
    nsf_daas_prd.data.case_dim c
    join temp_orders ta on c.case_hub_id = ta.case_hub_id
	)
FILE_FORMAT = (   TYPE = CSV
		, FIELD_DELIMITER='|'
		, FILE_EXTENSION = '.CSV'
		, NULL_IF = ('')
		, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
		, COMPRESSION=NONE
		, EMPTY_FIELD_AS_NULL = FALSE
		, TRIM_SPACE = TRUE
		  ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;

COPY INTO @offload/IMAGE_DATA_20250609
FROM (     
	select distinct
    i.ACCESSION_HUB_ID,
--    ACCESSION_SRC_ID,
    i.CASE_HUB_ID,
--    CASE_SRC_ID,
--    CASE_NO,
    i.TEST_ORDER_HUB_ID,
--    TEST_ORDER_SRC_ID,
    i.TEST_CODE,
    i.TEST_NAME,
    EXTERNAL_IMAGE_IDENTIFIER,
    EXTERNAL_IMAGE_PATH,
    IMAGE_HOST_NAME,
    IMAGE_DIRECTORY,
    IMAGE_FILENAME,
    LENGTH_IN_BYTES,
    FILE_CREATED_DTS_LOCAL,
    FILE_CREATED_DTS_UTC,
    SITE_CODE,
    ARCHIVE_STATUS,
    SCAN_NUMBER,
    SCAN_TYPE,
--    SCANNED_DTS,
    SCAN_STATUS_MESSAGE,
    SCAN_INSTRUMENT,
--    QC_DTS,
    QC_CHOICE,
    QC_REASON,
--    QC_USERNAME,
    QC_COMMENTS,
--    IMAGE_METADATA_CREATED_DTS,
--    IMAGE_METADATA_MODIFIED_DTS,
    IMAGE_RECONCILE_STATUS,
--    IMAGE_RECONCILOR_FIRST_PROCESSED_DTS,
--    IMAGE_RECONCILOR_LAST_PROCESSED_DTS,
--    IMAGE_RECONCILOR_ERROR_MESSAGE,
--    SPECIMEN,
--    INFORMATICS_EXCLUDE_REASON,
    IMAGE_QUALITY_TAG,
    ICC_PROFILE,
    IMAGE_FORMAT,
    SCANNER_PLATFORM,
    SCAN_MAGNIFICATION,
--    THUMBNAILL_EXISTS,
--    THUMBNAIL_ID,
    IMAGE_HEIGHT,
    IMAGE_WIDTH,
    MPP
from
    nsf_daas_prd.data.image_fact i
    join temp_orders ta on i.test_order_hub_id = ta.test_order_hub_id
	)
FILE_FORMAT = (   TYPE = CSV
		, FIELD_DELIMITER='|'
		, FILE_EXTENSION = '.CSV'
		, NULL_IF = ('')
		, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
		, COMPRESSION=NONE
		, EMPTY_FIELD_AS_NULL = FALSE
		, TRIM_SPACE = TRUE
		  ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;




 
COPY INTO @offload/PATIENT_DATA_20250609
FROM (      
    select distinct
     p.PATIENT_HUB_ID, 
 --    PATIENT_SRC_ID, 
 --    PATIENT_UNIQUE_ID, 
 --    PATIENT_FIRST_NAME, 
 --    PATIENT_MIDDLE_NAME, 
 --    PATIENT_LAST_NAME, 
     PATIENT_GENDER, 
     PATIENT_DATE_OF_BIRTH, 
     PATIENT_AGE_CURRENT, 
 --    PATIENT_ADDR1, PATIENT_ADDR2, PATIENT_CITY, 
     PATIENT_STATE, 
     PATIENT_POSTAL_CODE--, 
 --    DATAVANT_TOKEN_1_VALUE, 
 --    DATAVANT_TOKEN_2_VALUE  
    from
        nsf_daas_prd.data.patient_dim p
    join temp_orders ta
        on p.patient_hub_id = ta.patient_hub_id
	)
FILE_FORMAT = (   TYPE = CSV
		, FIELD_DELIMITER='|'
		, FILE_EXTENSION = '.CSV'
		, NULL_IF = ('')
		, FIELD_OPTIONALLY_ENCLOSED_BY = '"'
		, COMPRESSION=NONE
		, EMPTY_FIELD_AS_NULL = FALSE
		, TRIM_SPACE = TRUE
		  ) , HEADER=TRUE, MAX_FILE_SIZE = 50000000;
    
	
GET @offload file://C:\Users\jay.blattner\Downloads\CAYLENT\ PARALLEL = 5;