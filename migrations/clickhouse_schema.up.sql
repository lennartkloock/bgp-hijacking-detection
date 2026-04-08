CREATE TABLE events (
    timestamp DateTime64(3),
    event_type Enum8('announcement' = 1, 'withdrawal' = 2),
    prefix_addr IPv6,
    prefix_len UInt8,
    origin_asn Array(UInt32),
    peer_asn UInt32,
    peer_ip IPv6,
    host UInt8,
    next_hop Array(IPv6)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (timestamp, prefix_addr, prefix_len);
