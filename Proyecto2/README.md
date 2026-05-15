# Nombre del proyecto
Sumador Decimal en FPGA con Teclado Matricial y Display de 7 Segmentos

## 1. Abreviaturas y definiciones
- FPGA: Field Programmable Gate Array.
- FSM: Finite State Machine (Máquina de Estados Finita).
- BCD: Binary Coded Decimal.
- DUT: Device Under Test.
- P&R: Place and Route.
- VCD: Value Change Dump.
- Debounce: Técnica utilizada para eliminar rebotes mecánicos en señales digitales.

## 2. Referencias
[0] David Harris y Sarah Harris. Digital Design and Computer Architecture. RISC-V Edition. Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3.

[1] Documentación oficial Tang Nano 9K – Sipeed.

[2] Documentación Yosys Open Synthesis Suite.

[3] Documentación nextpnr-gowin.

## 3. Desarrollo
### 3.0 Descripción general del sistema
El sistema implementado consiste en una calculadora decimal desarrollada sobre una FPGA Tang Nano 9K. El sistema permite ingresar dos números enteros positivos utilizando un teclado hexadecimal matricial de 4x4, realizar la suma aritmética de ambos operandos y mostrar el resultado en displays de siete segmentos multiplexados.

El diseño completo opera de manera síncrona utilizando el reloj principal de 27 MHz proporcionado por la FPGA.

La arquitectura del sistema se divide en tres bloques principales:

Subsistema de lectura de teclado.
Subsistema de procesamiento aritmético.
Subsistema de visualización en displays de siete segmentos.

El sistema fue desarrollado utilizando SystemVerilog y validado mediante simulación funcional, síntesis lógica, place and route y generación de bitstream para FPGA.

### 3.1 Organización del Proyecto
src/
│
├── build/
│   └── Makefile
│
├── constr/
│   ├── pines.cst
│   └── tangnano9k_constrains_template.txt
│
├── design/
│   ├── keypad_scanner.sv
│   ├── seven_seg_display.sv
│   └── top.sv
│
└── sim/
    ├── tb_subsistema1.sv
    ├── tb_subsistema2.sv
    ├── tb_subsistema3.sv
    └── tb_top.sv

### 3.2 Subsistema 1 – Lectura de Teclado Matricial
Encabezado del módulo:
module keypad_scanner (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] filas_raw,
    output logic [3:0] columnas,
    output logic [3:0] key_code,
    output logic       key_valid
);

Este subsistema es el encargado de detectar las teclas presionadas en el teclado hexadecimal matricial 4x4.

El módulo implementa:

Barrido secuencial de columnas.
Sincronización de entradas.
Eliminación de rebotes mecánicos.
Decodificación hexadecimal.
Generación de pulsos válidos de tecla.

El teclado opera mediante multiplexación de columnas utilizando un esquema one-hot.

El sistema activa una columna a la vez y verifica si alguna fila presenta un valor lógico alto. Cuando esto ocurre, se identifica la posición de la tecla y posteriormente se realiza un proceso de debounce para validar la pulsación.

La detección de teclas se controla mediante una máquina de estados finita (FSM) compuesta por cuatro estados:

SCAN
DEBOUNCE_PRESS
WAIT_RELEASE
DEBOUNCE_RELEASE

Esto garantiza que:

no existan falsas detecciones,
no se repitan teclas por rebote,
cada pulsación genere únicamente un pulso válido.

El teclado utiliza codificación hexadecimal:
| Tecla | Código Hex |
| ----- | ---------- |
| 0     | 0x0        |
| 1     | 0x1        |
| 2     | 0x2        |
| 3     | 0x3        |
| 4     | 0x4        |
| 5     | 0x5        |
| 6     | 0x6        |
| 7     | 0x7        |
| 8     | 0x8        |
| 9     | 0x9        |
| A     | 0xA        |
| B     | 0xB        |
| C     | 0xC        |
| D     | 0xD        |
| *     | 0xE        |
| #     | 0xF        |

Las teclas especiales fueron utilizadas de la siguiente manera:

* → reinicio del ingreso.
# → confirmación del número ingresado.

Debido a que las entradas provenientes del teclado son señales asíncronas respecto al reloj de la FPGA, se implementó un sincronizador de doble flip-flop para evitar problemas de metaestabilidad.
Posteriormente se aplicó una etapa de debounce de aproximadamente 20 ms para eliminar rebotes mecánicos generados por las teclas físicas.

Se desarrolló un testbench funcional que simula la pulsación real de teclas del teclado matricial.

Las pruebas realizadas incluyen:

Ingreso de números completos.
Confirmación mediante tecla #.
Reinicio mediante tecla *.
Verificación de límite máximo de tres dígitos.
Validación de registros internos.

Los resultados obtenidos fueron correctos en todos los escenarios evaluados.

### 3.3 Subsistema 2 – Suma Aritmética
El subsistema aritmético realiza la suma decimal de los dos números ingresados desde el teclado.

La operación se ejecuta utilizando lógica combinacional y registros BCD internos.

El diseño soporta:

números de hasta tres dígitos,
resultados de hasta cuatro dígitos,
manejo de acarreo decimal.

La suma se realiza dígito por dígito:

unidades,
decenas,
centenas.

Cada etapa verifica si el resultado supera el valor decimal 9 para generar el acarreo correspondiente.

El resultado final se almacena en:

res_d3 res_d2 res_d1 res_d0

permitiendo representar resultados desde 0 hasta 1998.

Las simulaciones realizadas incluyen:
| Operación | Resultado |
| --------- | --------- |
| 123 + 456 | 579       |
| 9 + 5     | 14        |
| 999 + 1   | 1000      |
| 150 + 750 | 900       |
| 320 + 640 | 960       |

Todos los resultados fueron correctos durante la simulación.

### 3.4 Subsistema 3 – Display de 7 Segmentos
Encabezado del módulo:
module seven_seg_display (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] digit0,
    input  logic [3:0] digit1,
    input  logic [3:0] digit2,
    input  logic [3:0] digit3,
    input  logic [3:0] en_mask,
    output logic [6:0] seg_7,
    output logic [3:0] AN
);

Este módulo controla los displays de siete segmentos de la FPGA utilizando multiplexación temporal.

Debido a que los cuatro displays comparten las líneas de segmentos, únicamente un display se activa a la vez.

La selección se realiza utilizando un contador de refresco sincronizado con el reloj principal.

El sistema utiliza los bits altos del contador de refresco para alternar entre los cuatro displays.

La velocidad de refresco es suficientemente alta para que el ojo humano perciba todos los displays encendidos simultáneamente.

El módulo implementa un decodificador hexadecimal a siete segmentos que permite representar:

números del 0 al 9,
caracteres hexadecimales A–F.

Se implementó una máscara de habilitación denominada en_mask.

Esta máscara permite:

apagar displays no utilizados,
mejorar la visualización,
evitar mostrar ceros innecesarios.

PinOut del Display utilizado:
![image alt]([https://github.com/Jei-UP/Proyectos-de-Dise-o-L-gico/blob/53c8b962ba57e8c2df3f141ea72fccd93ebfdbb1/Proyecto2/images/Ejercicio%201/MSB.png](https://github.com/Jei-UP/Proyectos-de-Dise-o-L-gico/blob/2c41d96f0057794e207db3bb1c00d439087ecfe3/Proyecto2/images/diagramas/Displays%20pinout.jpeg)

### 3.5 Módulo Top
El módulo top integra todos los subsistemas del proyecto:

lectura de teclado,
procesamiento aritmético,
control de displays.

Además, implementa la FSM principal encargada de controlar:

ingreso del primer número,
ingreso del segundo número,
visualización del resultado.

Los estados implementados son:
INGRESO_N1
INGRESO_N2
MOSTRAR_SUMA

### 3.6 Simulación del Sistema Completo
Se desarrolló un testbench general (tb_top.sv) para validar la operación completa del sistema.
Las pruebas realizadas incluyen:
| Operación | Resultado Esperado |
| --------- | ------------------ |
| 251 + 302 | 553                |
| 526 + 67  | 593                |
| 150 + 750 | 900                |
| 320 + 640 | 960                |

La simulación verificó correctamente:

lectura del teclado,
transición de estados,
suma aritmética,
despliegue en displays.

### 3.7 Implementación en FPGA
Para la implementación física del sistema se utilizó el flujo open-source basado en:

Yosys
nextpnr-gowin
gowin_pack
openFPGALoader

El proceso completo se ejecutó mediante el archivo Makefile.

### 3.8 Ejercicios extra del proyecto:
####  3.8.1 Contadores:
La salida RCO del 74LS163 indica el estado terminal del contador (1111) y se utiliza para habilitar el siguiente contador en cascada. La conexión RCO → T permite extender el conteo a múltiples etapas de forma síncrona.
Las entradas ENP (P) y ENT (T) deben estar activas simultáneamente para habilitar el conteo.
El retardo de propagación típico del dispositivo es del orden de decenas de nanosegundos, por lo que las transiciones no son instantáneas.
El disparo del osciloscopio se realiza preferentemente en el bit más significativo debido a su menor frecuencia y mayor estabilidad.
Se pueden observar posibles glitches en la señal RCO debido a retardos internos desbalanceados, especialmente durante transiciones donde múltiples bits cambian simultáneamente.

Señal de CLK obtenida desde la FPGA:
![image alt](https://github.com/Jei-UP/Proyectos-de-Dise-o-L-gico/blob/53c8b962ba57e8c2df3f141ea72fccd93ebfdbb1/Proyecto2/images/Ejercicio%201/Reloj%20Fpga.png)

Señal obtenida del MSB del contador:
![image alt](https://github.com/Jei-UP/Proyectos-de-Dise-o-L-gico/blob/53c8b962ba57e8c2df3f141ea72fccd93ebfdbb1/Proyecto2/images/Ejercicio%201/MSB.png)

## 4. Archivo de Constraints
El archivo pines.cst define la asignación física de pines de la FPGA Tang Nano 9K.

Las señales asignadas incluyen:

reloj principal,
reset,
filas del teclado,
columnas del teclado,
segmentos del display,
ánodos de displays.

También se configuraron resistencias pull-down en las entradas del teclado para evitar estados flotantes.

## 5. Problemas Encontrados Durante el Proyecto
Durante el desarrollo del proyecto se encontraron varios problemas técnicos importantes:

Rebotes mecánicos del teclado matricial.
Problemas de sincronización en señales asíncronas.
Ajuste de tiempos de debounce.
Multiplexación incorrecta de displays.
Manejo de acarreos decimales.
Compatibilidad de SystemVerilog con Yosys.
Ajuste de tiempos de simulación.
Control de displays activos en alto.
Verificación de overflow.
Integración entre módulos.

Todos los problemas fueron corregidos satisfactoriamente.

## 6. Consumo de Recursos
El diseño final fue sintetizado exitosamente para la FPGA Tang Nano 9K.

La implementación cumplió correctamente con:

frecuencia objetivo de 27 MHz,
utilización válida de LUTs,
utilización válida de flip-flops,
generación correcta del bitstream final.

## 7. Conclusiones
Se logró implementar correctamente una calculadora decimal completamente funcional utilizando FPGA y SystemVerilog.

El sistema permitió capturar datos desde un teclado hexadecimal matricial, procesar operaciones aritméticas y desplegar resultados utilizando displays de siete segmentos multiplexados.

Además, el proyecto permitió aplicar conceptos fundamentales de diseño digital como:

máquinas de estados,
sincronización,
multiplexación,
debounce,
diseño síncrono,
simulación funcional,
síntesis lógica.

Finalmente, todas las pruebas realizadas tanto en simulación como en síntesis fueron exitosas, validando el funcionamiento correcto del sistema completo.

## 8. Apéndices

### Apéndice A – Herramientas utilizadas
SystemVerilog
Yosys
nextpnr-gowin
gowin_pack
GTKWave
Icarus Verilog
openFPGALoader

### Apéndice B – FPGA utilizada
Tang Nano 9K
Gowin GW1NR-LV9QN88PC6/I5
