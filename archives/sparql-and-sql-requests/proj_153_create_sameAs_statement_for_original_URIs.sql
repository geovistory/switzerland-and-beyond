

-- list imported persons with original URI
SELECT t1.pk_entity,
       t1.entity_label,
       t3.uri_entity
FROM war.entity_preview t1,
     importer_dbpedia.entity t3
WHERE t1.fk_project = 153
AND   t1.fk_class = 21
AND   t3.fk_entity_information_schema = t1.pk_entity;

/*
Creation of the "crm-sup:C30 Uniform Resource Identifier (URI)" class instances corresponding
to the original URI from which the data was produced in 2018
In the import metadata you'll find the created person pk_entity,
the original URI and the import table pk 
*/
--INSERT INTO information.resource (fk_class,fk_creator,fk_last_modifier,metadata) 
WITH tw1 AS
(
  SELECT t1.pk_entity,
         t1.entity_label,
         t2.uri_entity,
         t2.pk_entity importer_pk
  FROM war.entity_preview t1,
       importer_dbpedia.entity t2
  WHERE t1.fk_project = 153
  AND   t1.fk_class = 21
  AND   t2.fk_entity_information_schema = t1.pk_entity
)
SELECT DISTINCT 967,
       8,
       8,
       ('{"source": {"import_id": "import_20220807_1", "original_uri": "' || uri_entity || '",
          "importer_dbpedia_entity": ' || importer_pk ||  ', "digital_label": "Création des URI à partir des personnes importées", 
          "pk_entity": ' || pk_entity || '}}')::JSONB import_metadata
FROM tw1;

-- Inspect import
SELECT *
FROM information.resource
WHERE TRIM((metadata #> '{"source","import_id"}')::VARCHAR,'"') = 'import_20220807_1'
ORDER BY pk_entity DESC
LIMIT 10;

/*
Creation of the "P28	same as URI [owl:sameAs] (same as)" statement associating the person 
with the original URI
*/
INSERT INTO information.statement(fk_property,fk_creator,fk_last_modifier,fk_subject_info,fk_object_info,metadata) 
SELECT 1943,
       8,
       8,
       (metadata #> '{"source","pk_entity"}')::VARCHAR::INTEGER person,
       pk_entity uri,
       ('{"source": {"import_id": "import_20220807_2"}}')::JSONB
FROM information.resource
WHERE TRIM('"' FROM (metadata #> '{"source","import_id"}')::TEXT) = 'import_20220807_1';

-- Inspect import
SELECT *
FROM information.statement
WHERE TRIM((metadata #> '{"source","import_id"}')::VARCHAR,'"') = 'import_20220807_2'
ORDER BY pk_entity DESC
LIMIT 10;

/***
URI AS APPELLATIONS

Create
*/ 

INSERT INTO information.appellation (fk_class,fk_creator,fk_last_modifier,string, metadata)
SELECT 339,
       8,
       8,
       (TRIM('"' FROM (t1.metadata #> '{"source","original_uri"}')::TET)) orig_uri,
       ('{"source": {"import_id": "import_20220807_3", "digital_label": "Création des URI à partir des personnes importées", 
          "pk_entity": ' || pk_entity || '}}')::JSONB import_metadata
FROM information.resource t1
WHERE TRIM('"' FROM (t1.metadata #> '{"source","import_id"}')::TEXT) = 'import_20220807_1';


SELECT COUNT(*)
FROM information.entity
WHERE TRIM((metadata #> '{"source","import_id"}')::VARCHAR,'"') = 'import_20220807_3';


/*
Creation of the "P21	has value (is value of)" statement associating the URI 
with the URI string (table appellation)
*/
INSERT INTO information.statement(fk_property,fk_creator,fk_last_modifier,fk_subject_info,fk_object_info,metadata) 
SELECT 1843,
       8,
       8,
       t1.pk_entity,
       t2.pk_entity pk_uri,
       ('{"source": {"import_id": "import_20220807_4"}}')::JSONB
FROM information.resource t1, information.appellation t2
WHERE TRIM('"' FROM (t1.metadata #> '{"source","import_id"}')::TEXT) = 'import_20220807_1'
AND t2.string = (t1.metadata #> '{"source","original_uri"}')::TEXT;

-- verify
SELECT count(*)
FROM information.statement
WHERE TRIM((metadata #> '{"source","import_id"}')::VARCHAR,'"') = 'import_20220807_4';



/*
Creation of the associations to the project

Beware !!!
Add 'CALENDAR' when associating time-primitives !!!


*/
INSERT INTO projects.info_proj_rel
(
  entity_version,
  fk_entity,
  fk_creator,
  fk_last_modifier,
  fk_project,
  --calendar,
  is_in_project,
  notes
)
SELECT 1,
       pk_entity,
       fk_creator,
       fk_last_modifier,
       153,
       --'gregorian',
       TRUE,
       'import_20220807_2' || '_project_association'
FROM information.entity
WHERE TRIM((metadata #> '{"source","import_id"}')::VARCHAR,'"') = 'import_20220807_2'
ORDER BY pk_entity DESC;

-- Inspect creation
SELECT COUNT(*)
FROM projects.info_proj_rel
WHERE notes = 'import_20220807_2_project_association';

/*
DONE FOR:
import_20220807_1
import_20220807_2
import_20220807_4
*/ 




