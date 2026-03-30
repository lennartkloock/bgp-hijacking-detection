-- The live routing table
CREATE TABLE routes (
    prefix CIDR NOT NULL,
    origin_asn BIGINT[] NOT NULL,
    peer_asn BIGINT NOT NULL,
    peer_ip INET NOT NULL,
    host VARCHAR(20) NOT NULL, -- e.g. "rrc21"
    as_path JSONB NOT NULL, -- ordered, origin last
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (prefix, peer_ip, host) -- one route per peering session
);

-- Only a hash index to keep it smaller
CREATE INDEX routes_prefix_hash_idx ON routes USING hash (prefix);
CREATE INDEX ON routes (origin_asn);
CREATE INDEX ON routes (updated_at);
CREATE INDEX ON routes USING GIST (prefix inet_ops);

-- CREATE TYPE event_type AS ENUM ('announcement', 'withdrawal');

-- -- Log of all raw UPDATE events
-- CREATE TABLE events (
--     id BIGSERIAL PRIMARY KEY,
--     timestamp TIMESTAMPTZ NOT NULL,
--     event_type event_type NOT NULL,
--     prefix CIDR NOT NULL,
--     origin_asn BIGINT[], -- NULL for withdrawals
--     peer_asn BIGINT NOT NULL,
--     peer_ip INET NOT NULL,
--     host VARCHAR(20) NOT NULL, -- e.g. "rrc21"
--     next_hop INET[] -- NULL for withdrawals
-- );

CREATE TABLE moas (
    prefix CIDR PRIMARY KEY,
    origins BIGINT[] NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
