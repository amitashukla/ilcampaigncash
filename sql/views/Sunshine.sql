CREATE MATERIALIZED VIEW most_recent_filings AS
 SELECT COALESCE(d2.end_funds_available, (0)::double precision) AS end_funds_available,
    COALESCE(d2.total_investments, (0)::double precision) AS total_investments,
    COALESCE(d2.total_debts, (0)::double precision) AS total_debts,
    COALESCE((d2.inkind_itemized + d2.inkind_non_itemized), (0)::double precision) AS total_inkind,
    cm.name AS committee_name,
    cm.id AS committee_id,
    cm.type AS committee_type,
    cm.active AS committee_active,
    fd.id AS filed_doc_id,
    fd.doc_name,
    fd.reporting_period_end,
    fd.reporting_period_begin,
    fd.received_datetime
   FROM ((committees cm
     LEFT JOIN ( SELECT DISTINCT ON (f.committee_id) f.id,
            f.committee_id,
            f.doc_name,
            f.reporting_period_end,
            f.reporting_period_begin,
            f.received_datetime
           FROM ( SELECT DISTINCT ON (filed_docs.committee_id, filed_docs.reporting_period_end) filed_docs.id,
                    filed_docs.committee_id,
                    filed_docs.doc_name,
                    filed_docs.reporting_period_end,
                    filed_docs.reporting_period_begin,
                    filed_docs.received_datetime
                   FROM filed_docs
                  WHERE ((filed_docs.doc_name)::text <> ALL ((ARRAY['A-1'::character varying, 'Statement of Organization'::character varying, 'Letter/Correspondence'::character varying, 'B-1'::character varying, 'Nonparticipation'::character varying])::text[]))
                  ORDER BY filed_docs.committee_id, filed_docs.reporting_period_end DESC, filed_docs.received_datetime DESC) f
          ORDER BY f.committee_id, f.reporting_period_end DESC) fd ON ((fd.committee_id = cm.id)))
     LEFT JOIN d2_reports d2 ON ((fd.id = d2.filed_doc_id)))
  WITH DATA;

 CREATE MATERIALIZED VIEW condensed_receipts AS
 SELECT r.id,
    r.committee_id,
    r.filed_doc_id,
    r.etrans_id,
    r.last_name,
    r.first_name,
    r.received_date,
    r.amount,
    r.aggregate_amount,
    r.loan_amount,
    r.occupation,
    r.employer,
    r.address1,
    r.address2,
    r.city,
    r.state,
    r.zipcode,
    r.d2_part,
    r.description,
    r.vendor_last_name,
    r.vendor_first_name,
    r.vendor_address1,
    r.vendor_address2,
    r.vendor_city,
    r.vendor_state,
    r.vendor_zipcode,
    r.archived,
    r.country,
    r.redaction_requested
   FROM (receipts r
     LEFT JOIN most_recent_filings m USING (committee_id))
  WHERE ((r.received_date > COALESCE(m.reporting_period_end, '1900-01-01 00:00:00'::timestamp without time zone)) AND (r.archived = false))
UNION
 SELECT r.id,
    r.committee_id,
    r.filed_doc_id,
    r.etrans_id,
    r.last_name,
    r.first_name,
    r.received_date,
    r.amount,
    r.aggregate_amount,
    r.loan_amount,
    r.occupation,
    r.employer,
    r.address1,
    r.address2,
    r.city,
    r.state,
    r.zipcode,
    r.d2_part,
    r.description,
    r.vendor_last_name,
    r.vendor_first_name,
    r.vendor_address1,
    r.vendor_address2,
    r.vendor_city,
    r.vendor_state,
    r.vendor_zipcode,
    r.archived,
    r.country,
    r.redaction_requested
   FROM (receipts r
     JOIN ( SELECT DISTINCT ON (filed_docs.reporting_period_begin, filed_docs.reporting_period_end, filed_docs.committee_id) filed_docs.id AS filed_doc_id
           FROM filed_docs
          WHERE ((filed_docs.doc_name)::text <> 'Pre-election'::text)
          ORDER BY filed_docs.reporting_period_begin, filed_docs.reporting_period_end, filed_docs.committee_id, filed_docs.received_datetime DESC) f USING (filed_doc_id))
  WITH DATA;


CREATE MATERIALIZED VIEW condensed_expenditures AS
 SELECT e.id,
    e.committee_id,
    e.filed_doc_id,
    e.etrans_id,
    e.last_name,
    e.first_name,
    e.expended_date,
    e.amount,
    e.aggregate_amount,
    e.address1,
    e.address2,
    e.city,
    e.state,
    e.zipcode,
    e.d2_part,
    e.purpose,
    e.candidate_name,
    e.office,
    e.supporting,
    e.opposing,
    e.archived,
    e.country,
    e.redaction_requested
   FROM (expenditures e
     JOIN most_recent_filings m USING (committee_id))
  WHERE ((e.expended_date > COALESCE(m.reporting_period_end, '1900-01-01 00:00:00'::timestamp without time zone)) AND (e.archived = false))
UNION
 SELECT e.id,
    e.committee_id,
    e.filed_doc_id,
    e.etrans_id,
    e.last_name,
    e.first_name,
    e.expended_date,
    e.amount,
    e.aggregate_amount,
    e.address1,
    e.address2,
    e.city,
    e.state,
    e.zipcode,
    e.d2_part,
    e.purpose,
    e.candidate_name,
    e.office,
    e.supporting,
    e.opposing,
    e.archived,
    e.country,
    e.redaction_requested
   FROM (expenditures e
     JOIN ( SELECT DISTINCT ON (filed_docs.reporting_period_begin, filed_docs.reporting_period_end, filed_docs.committee_id) filed_docs.id AS filed_doc_id
           FROM filed_docs
          WHERE ((filed_docs.doc_name)::text <> 'Pre-election'::text)
          ORDER BY filed_docs.reporting_period_begin, filed_docs.reporting_period_end, filed_docs.committee_id, filed_docs.received_datetime DESC) f USING (filed_doc_id))
  WITH DATA;
