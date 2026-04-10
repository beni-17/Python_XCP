import time
import struct
from pyxcp.cmdline import ArgumentParser
from pyxcp.daq_stim import DaqList, DaqToCsv
import Teensy_ModelAddr as addr


FMT_U16 = "<H"
FMT_F32 = "<f"
FMT_BOOL = "<?"

DAQ_LISTS = [
    # (EVENT 0x0000)
    DaqList(
        name="firsTest",
        event_num=0,
        stim=False,
        enable_timestamps=True,
        measurements=[
            ("mdCurrent",   addr.ADDR_MD_CURRENT,   0, "U16"),
            ("torqSignal", addr.ADDR_TORQ_SIGNAL, 0, "U16"),
        ],
        priority=0,
        prescaler=1,
    ),
]

def main():
    ap = ArgumentParser(description="DAQ demo (Teensy, XCP on SxI)")
    daq_policy = DaqToCsv(DAQ_LISTS)   # writes for each daq list a csv

    with ap.run(policy=daq_policy) as x:
        print("Port opened, waiting for Teensy bootloader...")
        time.sleep(3.0)

        x.connect()

        # unlock daq slave
        x.cond_unlock("DAQ")

        # daq policy setup
        daq_policy.setup()
        print("Starting DAQ ...")
        daq_policy.start()

        time.sleep(5)  # aqcuise data for 5s

        # read current state of ADDR_MOTOR_ENABLE, invert statem, write back
        x.setMta(addr.ADDR_MOTOR_ENABLE)
        raw2 = x.upload(1)
        val = struct.unpack(FMT_BOOL, raw2)[0]
        print("init reading ADDR_MOTOR_ENABLE Param =", val)
        new_val = not val
        print("Writing ADDR_MOTOR_ENABLE Param =", new_val)
        x.setMta(addr.ADDR_MOTOR_ENABLE)
        x.download(struct.pack(FMT_BOOL, new_val))

        x.setMta(addr.ADDR_MOTOR_ENABLE)
        raw2 = x.upload(1)
        val2 = struct.unpack(FMT_BOOL, raw2)[0]
        print("ADDR_MOTOR_ENABLE Param readback =", val2)

        time.sleep(5)  # aqcuise data for another 5s

        print("Stopping DAQ ...")
        daq_policy.stop()
        x.disconnect()

    # DaqToCsv writes csv
    if hasattr(daq_policy, "files"):
        print("CSV files:")
        for k, v in daq_policy.files.items():
            print(f"  {k}: {v.name}")

if __name__ == "__main__":
    main()
