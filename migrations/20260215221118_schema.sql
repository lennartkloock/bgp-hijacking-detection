CREATE TABLE "prefixes" (
    "prefix" CIDR NOT NULL,
    "origin_asn" BIGINT NOT NULL,
    "announced_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "withdrawn_at" TIMESTAMPTZ DEFAULT NULL,
    PRIMARY KEY ("prefix", "origin_asn")
);

CREATE INDEX idx_prefixes_prefix_gist ON prefixes USING GIST (prefix inet_ops);

-- CREATE TABLE "moas" (
--     "prefix" CIDR NOT NULL,
--     "new_origin_asn" BIGINT NOT NULL,
--     "existing_origin_asn" BIGINT NOT NULL,
--     "detected_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- CREATE OR REPLACE FUNCTION detect_moas() RETURNS TRIGGER AS $$ BEGIN
--     INSERT INTO moas (
--         prefix,
--         new_origin_asn,
--         existing_origin_asn
--     )
--     SELECT p.prefix,
--         NEW.origin_asn,
--         p.origin_asn
--     FROM prefixes p
--     WHERE p.prefix = NEW.prefix
--         AND p.origin_asn != NEW.origin_asn
--         AND p.ctid != NEW.ctid;

--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_detect_moas
-- AFTER
-- INSERT ON prefixes FOR EACH ROW EXECUTE FUNCTION detect_moas();
