# -- EXTERNO --
import os
import time

# -- SENSOR DO MOUSE -- 
VENDOR_ID = '1D57'
PRODUCT_ID = 'FA65'

# -- CAMINHO PARA A PASTA HIDRAW --
MODALIAS = ['/sys/class/hidraw/', '/device/modalias']

# -- COMANDO HID --
COMMAND = [
    0x00, 0x1b, 0x00, 0x10, 0xb0, 0x66, 0xa6, 0x07,
    0xa8, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x09,
    0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x82, 0x01,
    0x00, 0x00, 0x00, 0x00
]

class HidCommunication():
    def get_hidraw_devices(self) -> list:
        hidraw_devices = []

        for hidraw in os.listdir(MODALIAS[0]):
            with open(f'{MODALIAS[0]}{hidraw}{MODALIAS[1]}', 'r') as file:
                for line_num, line in enumerate(file, start = 1):
                    if VENDOR_ID in line and PRODUCT_ID in line:
                        hidraw_devices.append(hidraw)

        return hidraw_devices


    def get_battery_level(self) -> int:
        for device in self.get_hidraw_devices():
            try:
                # -- DISPARANDO PESQUISA --
                with open(f'/dev/{device}', 'wb') as file:
                    file.write(bytearray(COMMAND))

                time.sleep(1)

                with open(f'/dev/{device}', 'rb') as file:
                    response = file.read(64)

                return int(response[4])

            except BrokenPipeError:
                pass


def main() -> None:
    hd = HidCommunication()
    print(hd.get_battery_level())


if __name__ == '__main__':
    main()

