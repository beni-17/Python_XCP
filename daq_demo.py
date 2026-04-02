import time
import struct
from pyxcp.cmdline import ArgumentParser
from pyxcp.daq_stim import DaqList, DaqToCsv

# Adresses from A2L (arduino_xcponserial_CANape_2023b.a2l)
ADDR_COUNTER   = 0x20001CE4  # UWORD
ADDR_SINE_WAVE = 0x20001CDC  # FLOAT32_IEEE
ADDR_PULSE     = 0x20001CD8  # ULONG
ADDR_OUT2      = 0x20001CEC  # FLOAT32_IEEE
ADDR_PULSE_AMP = 0x20000B70  # FLOAT32_IEEE
ADDR_CONST_AMP = 0x20000B18  # FLOAT32_IEEE
ADDR_CONST_SIG = 0x20001CE0  # FLOAT32_IEEE

FMT_U16 = "<H"
FMT_F32 = "<f"

DAQ_LISTS = [
    # 100 ms Event (EVENT 0x0000)
    DaqList(
        name="ev100ms",
        event_num=0,
        stim=False,
        enable_timestamps=True,
        measurements=[
            ("counter",   ADDR_COUNTER,   0, "U16"),
            ("sine_wave", ADDR_SINE_WAVE, 0, "F32"),
            ("out2",      ADDR_OUT2,      0, "F32"),
        ],
        priority=0,
        prescaler=1,
    ),

    # 200 ms Event (EVENT 0x0001)
    DaqList(
        name="ev200ms",
        event_num=1,
        stim=False,
        enable_timestamps=True,
        measurements=[
            ("pulse", ADDR_PULSE, 0, "U32"),
            ("const_sig", ADDR_CONST_SIG, 0, "F32"),
        ],
        priority=0,
        prescaler=1,
    ),
]

def main():
    ap = ArgumentParser(description="DAQ demo (Teensy, XCP on SxI)")
    daq_policy = DaqToCsv(DAQ_LISTS)   # schreibt pro DAQ-Liste eine CSV

    with ap.run(policy=daq_policy) as x:
        print("Port opened, waiting for Teensy bootloader...")
        time.sleep(3.0)

        x.connect()

        # Falls dein Slave DAQ sperrt, ist das der offizielle Weg:
        # (wenn nicht nötig, schadet es meistens nicht)
        x.cond_unlock("DAQ")

        # DAQ Listen automatisch allozieren/konfigurieren
        daq_policy.setup()
        print("Starting DAQ ...")
        daq_policy.start()

        time.sleep(5)  # 10s mitschneiden

        # WRITE + READBACK (optional)
        new_val = 1.0
        print("Writing CONST_AMP Param =", new_val)
        x.setMta(ADDR_CONST_AMP)
        x.download(struct.pack(FMT_F32, new_val))

        x.setMta(ADDR_CONST_AMP)
        raw2 = x.upload(4)
        val2 = struct.unpack(FMT_F32, raw2)[0]
        print("CONST_AMP Param readback =", val2)

        time.sleep(5)  # 10s mitschneiden

        print("Stopping DAQ ...")
        daq_policy.stop()
        x.disconnect()

    # DaqToCsv legt Dateien an; Pfad/Name hängt von Policy/WorkingDir ab
    if hasattr(daq_policy, "files"):
        print("CSV files:")
        for k, v in daq_policy.files.items():
            print(f"  {k}: {v.name}")

if __name__ == "__main__":
    main()
