type Etc_services::Protocols = Hash[
  Enum[
    'udp',
    'tcp',
  ],
  Integer[1,65535],
]
