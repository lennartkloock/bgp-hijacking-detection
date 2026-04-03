-- The live routing table
CREATE TABLE routes (
    prefix CIDR NOT NULL,
    origin_asn BIGINT[] NOT NULL,
    peer_asn BIGINT NOT NULL,
    peer_ip INET NOT NULL,
    host VARCHAR(20) NOT NULL, -- e.g. "rrc21"
    -- as_path JSONB NOT NULL, -- ordered, origin last
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (prefix, peer_ip, host) -- one route per peering session
);

CREATE TABLE moas (
    prefix CIDR PRIMARY KEY,
    origins BIGINT[] NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    https_hosts INET[] DEFAULT ARRAY[]::INET[],
    last_scanned_at TIMESTAMPTZ DEFAULT NULL
);
