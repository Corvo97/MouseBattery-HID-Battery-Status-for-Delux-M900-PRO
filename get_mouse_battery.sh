#!/bin/bash


# -- INFORMAÇÕES DO RECEPTOR DO MOUSE --
VENDOR_ID='1D57'
PRODUCT_ID='FA65'


# -- DIRETÓRIOS --
HIDRAW_PATH='/sys/class/hidraw'
MODALIAS='device/modalias'


# -- COMANDO HID HEXADECIMAL --
COMMAND_HEX='00 1b 00 10 b0 66 a6 07 a8 ff ff 00 00 00 00 09 00 00 01 00 02 00 82 01 00 00 00 00'


# -- FUNCOES --

get_hidraw_devices(){
    #
    # GERANDO LISTA DOS DISPOSITIVOS HIDRAW REFERENTES AO MOUSE
    #

    local devices=()

    for hidraw in $(ls "$HIDRAW_PATH"); do
        if [[ -f "$HIDRAW_PATH/$hidraw/$MODALIAS" ]]; then
            if grep -q "$VENDOR_ID" "$HIDRAW_PATH/$hidraw/$MODALIAS" && grep -q "$PRODUCT_ID" "$HIDRAW_PATH/$hidraw/$MODALIAS"; then
                devices+=("$hidraw")
            fi
        fi
    done

    echo "${devices[@]}"   
}


get_battery_level(){
    #
    # ENVIANDO COMANDO HID, OBTENDO RESPOSTA E FILTRANDO O NÍVEL DA BATERIA
    #

    for device in $(get_hidraw_devices); do
        # Convertendo comando hex em bytes e enviando ao dispositivo ->
        echo "$COMMAND_HEX" | xxd -r -p > "/dev/$device" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            # echo "Erro ao escrever no dispositivo $device, pulando para o próximo."
            continue

        else
            sleep 1

            # Lendo a resposta recebida do dispositivo ->
            response=$(dd if="/dev/$device" bs=64 count=1 2>/dev/null | hexdump -v -e '1/1 "%02X "')

            # Filtrando informações relevantes ->
            BATTERY_LEVEL=$(echo "$response" | awk '{print strtonum("0x"$5)}')
            BATTERY_CHARGING=$(echo "$response" | awk '{print strtonum("0x"$4)}')

            if [[ $BATTERY_LEVEL == "0" ]]; then
                echo "💤"
            fi

            # Indicador de carga ->
            if [[ $BATTERY_CHARGING == "3" ]]; then
                STATUS=$(echo '⚡')
            else
                STATUS=$(echo '%')
            fi

            # Indicador de bateria baixa ->
            if [[ $BATTERY_LEVEL -lt 10 ]]; then
                LOW=$(echo '❗')
            else
                LOW=$(echo '')
            fi

            # Concatenando informações ->
            WAYBAR_STRING=$(echo "$LOW$BATTERY_LEVEL$STATUS")
            
            # Printando saída para o waybar ->
            echo "$WAYBAR_STRING"
            
            break
        fi
    done
}


# -- main --
main(){
    get_battery_level
}

main