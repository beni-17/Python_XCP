# pyxcp_conf.py
c = get_config()  # noqa

c.Transport.layer = "SXI"
c.Transport.SxI.port = "COM3"
c.Transport.SxI.bitrate = 921600
c.Transport.SxI.bytesize = 8

# A2L: PARITY_NONE ONE_STOP_BIT
c.Transport.SxI.parity = "N"
c.Transport.SxI.stopbits = 1

# A2L: HEADER_LEN_CTR_BYTE
c.Transport.SxI.header_format = "HEADER_LEN_CTR_BYTE"

# NICHT setzen, bis wir wissen wie pyXCP es nennt:
c.Transport.SxI.tail_format = "CHECKSUM_BYTE"
