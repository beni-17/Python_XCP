import time
import struct
import time
from pyxcp.cmdline import ArgumentParser

ADDR_STEP_PARAM = 0x20000ED0  # UWORD (2 bytes)
FMT_U16 = "<H"

def main():
    ap = ArgumentParser(description="XCP Teensy minimal test")

    with ap.run() as x:
        print("Port opened, waiting for Teensy bootloader...")
        time.sleep(3.0)

        # CONNECT (mit Retries)
        for i in range(3):
            try:
                print(f"Connecting XCP (try {i+1}/3)...")
                x.connect()
                break
            except Exception as e:
                print("Connect failed:", e)
                time.sleep(1.0)
        else:
            raise RuntimeError("XCP connect failed after retries")

        # READ
        print("Reading STEP_PARAM...")
        x.setMta(ADDR_STEP_PARAM)
        raw = x.upload(2)
        val = struct.unpack(FMT_U16, raw)[0]
        print("STEP_PARAM =", val)

        # WRITE + READBACK (optional)
        new_val = (val + 1) & 0xFFFF
        print("Writing STEP_PARAM =", new_val)
        x.setMta(ADDR_STEP_PARAM)
        x.download(struct.pack(FMT_U16, new_val))

        x.setMta(ADDR_STEP_PARAM)
        raw2 = x.upload(2)
        val2 = struct.unpack(FMT_U16, raw2)[0]
        print("STEP_PARAM readback =", val2)

        ADDR_SINE_WAVE = 0x20001CDC  # FLOAT32_IEEE
        FMT_F32 = "<f"

        x.setMta(ADDR_SINE_WAVE)
        raw = x.upload(4)
        val = struct.unpack(FMT_F32, raw)[0]
        print("Sine_Wave =", val)

        for _ in range(20):
            x.setMta(ADDR_SINE_WAVE)
            raw = x.upload(4)
            print(struct.unpack("<f", raw)[0])
            time.sleep(0.1)

        x.disconnect()

if __name__ == "__main__":
    main()
