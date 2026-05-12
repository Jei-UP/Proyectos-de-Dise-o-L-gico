# Nombre del proyecto

## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays

## 2. Referencias
[0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3
[1] P. P. Chu. *FPGA Prototyping by SystemVerilog Examples: Xilinx MicroBlaze MCS SoC Edition*, 2nd ed. Hoboken, NJ, USA: Wiley, 2018.

## 3. Desarrollo

### 3.0 Descripción general del sistema
El sistema completo implementado en la FPGA tiene como objetivo capturar dos números enteros positivos de hasta tres dígitos decimales desde un teclado hexadecimal, realizar la suma aritmética sin signo de ambos valores y posteriormente desplegar los resultados en dispositivos de siete segmentos.

El diseño se estructura en tres subsistemas principales: lectura del teclado, suma aritmética y despliegue en displays. Cada subsistema opera de forma sincrónica bajo un único reloj de 27 MHz, garantizando coherencia temporal en todo el sistema.

### 3.1 Subsistema 1 (Lectura de teclado)
#### 1. Encabezado del módulo
```SystemVerilog
module mi_modulo(
    input logic     entrada_i,      
    output logic    salida_i 
    );
```

### 3.2 Subsistema 2: Suma aritmética de los datos

#### 3.2.1. Encabezado del módulo
```SystemVerilog
module subsistema_suma(
    input  logic        clk,
    input  logic        rst,

    input  logic        datos_listos,
    input  logic [9:0]  num1_reg,
    input  logic [9:0]  num2_reg,

    output logic [10:0] suma,
    output logic        suma_ready
);
```


#### 3.2.2. Parámetros
Este módulo no utiliza parámetros configurables. El tamaño de los buses está definido para soportar números de hasta 10 bits (0–999 en uso funcional) y un resultado de 11 bits para contemplar posibles desbordamientos.

#### 3.2.3. Entradas y salidas:
- num1_reg: primer número capturado por el subsistema de lectura (hasta 10 bits).
- num2_reg: segundo número capturado por el subsistema de lectura (hasta 10 bits).
- datos_listos: señal de control que indica que ambos números están disponibles.
- suma: resultado de la operación aritmética sin signo entre los dos operandos.
- suma_ready: señal de salida que indica que el resultado de la suma está disponible para el siguiente subsistema.

#### 3.2.4. Criterios de diseño
El subsistema de suma aritmética es el encargado de realizar la operación de adición entre los dos números enteros positivos capturados por el subsistema de lectura del teclado hexadecimal. Este módulo recibe como entrada los registros num1_reg y num2_reg, los cuales contienen los valores decimales de hasta tres dígitos cada uno, previamente validados y almacenados en la FPGA.

La operación de suma se realiza de forma sincrónica utilizando lógica descrita en SystemVerilog, aprovechando las capacidades de operación aritmética del lenguaje. El resultado se almacena en una señal de 11 bits (suma) para garantizar la representación correcta del resultado, incluyendo posibles casos de desbordamiento dentro del rango permitido por el sistema.

El subsistema se activa mediante la señal datos_listos, la cual indica que ambos operandos han sido capturados correctamente. Una vez realizada la suma, se genera la señal suma_ready, que notifica al siguiente subsistema que el resultado está disponible para su despliegue en los dispositivos de siete segmentos.

Este diseño garantiza una operación completamente sincrónica con el reloj del sistema (27 MHz), manteniendo la coherencia temporal entre los subsistemas.

#### 3.2.5. Testbench
Para la validación del subsistema de suma se desarrolló un testbench en SystemVerilog que permite verificar el comportamiento funcional del módulo bajo distintos escenarios representativos.

Las pruebas realizadas incluyen:

- 123 + 456 = 579
- 9 + 5 = 14
- 999 + 1 = 1000
- 1023 + 1 = 1024 (caso de prueba de estrés en ancho de palabra)

Los resultados obtenidos en simulación demuestran que el módulo realiza correctamente la operación aritmética en todos los casos, generando la señal suma_ready de forma adecuada para la sincronización con el subsistema de despliegue.


### 3.3 Subsistema 3: Despliegue de despliegue de código decodificado en display de 7 segmentos
Este sistema se encarga de tomar los datos, tanto del teclado (los dos operandos) como el resultado de la suma, en su forma BCD para decodificarla a su forma de 7 segmentos. Para este subsistema se toman en cuenta 4 módulos:
1. Primero, el módulo de counter. Este se encarga de dividir la frecuencia para que el selector de dígitos (sel) vaya a una frecuencia más baja que la del sistema para poder multiplexar los displays. 
2. Segundo, el digit_sel se encarga de ir por cada número, es decir, por cada operando (A y B) y el resultado final de la suma (S) y seleccionar el dígito que se va a desplegar en el display.
3. Tercero, el módulo display_7 se encarga de tomar el valor del dígito que se seleccionó en el módulo de digit_sel y hacer la conversión del BCD al 7seg (tomando en cuenta que el display a utilizar es un cátodo común). Luego, teniendo este valor en su forma 7 segmentos, se selecciona el segmento que se va a encender en el display y dependiendo del sel, se activará en alguno de los 4 dígitos. En otras palabras, activa un display, muestra un dígito y luego cambia al siguiente.
4. Por último, en registro_salida el módulo espera una señal (suma_ready), luego guarda los números en registros y genera una señal de confirmación (datos_listos). Básicamente guarda los valores para que no puedan cambiarse y así se realice la suma de forma correcta.

#### 3.3.2. Parámetros
En este subsistema no se presentan parámetros configurables.

#### 3.3.3. Entradas y salidas:
1. Módulo counter
-clk: reloj de la FPGA
-rst: reinicia el contador
-sel: selecciona qué dígito del display está activo (salida)
2. Módulo digit_sel
-sel: qué dígito del display se está usando
-mode: cuál número es, los operandos (A, B) o el resultado de la suma (S).
-dig_in: nibble que irá al display de 7 segmentos (salida).
3. Módulo display_7
-clk: reloj de la FPGA
-sel: qué dígito del display se está usando
-dig_in: nibble que se usará en el display de 7 segmentos.
-seg_7: nibble decodificado a 7 segmentos, señales del display (a,b,c,d,e,f,g) (salida).
-AN: activa uno de los 4 dígitos del display (salida).
4. Módulo registros_salida
-clk: reloj de la FPGA
-rst: reinicia el contador
-suma_ready: cuándo guardar los datos.
-numero1: primer operando
-numero2: segundo operando
-num1_reg: copia almacenada de numero1 (salida).
-num2_reg: copia almacenada de numero2 (salida).
-datos_listos: pulso que indica que todo fue guardado (salida).

#### 3.2.5. Testbench
Para verificar que el subsistema sí esté funcionando correctamente, se creó el test bench tb_subsistema3. Este básicamente simula el módulo display_7, donde se le manda distintos valores. Este verifica que se haga la conversión de BCD a 7 segmentos de forma correcta, que funcione el multiplexado del selector y también el comportamiento del subsistema frente a valores inválidos (letras en hexadecimal ).


Tiempo  | sel | dig_in  |   seg_7   |   AN
----------------------------------------------------
0       | 00  |  0      | 00111111 | 0001
50000   | 00  |  1      | 00000110 | 0001
150000  | 00  |  2      | 01011011 | 0001
250000  | 00  |  3      | 01001111 | 0001
350000  | 00  |  4      | 01100110 | 0001
450000  | 00  |  5      | 01101101 | 0001
550000  | 00  |  6      | 01111101 | 0001
650000  | 00  |  7      | 00000111 | 0001
750000  | 00  |  8      | 01111111 | 0001
850000  | 00  |  9      | 01101111 | 0001
950000  | 00  | 10      | 00000000 | 0001
1050000 | 00  |  5      | 01101101 | 0001
1150000 | 01  |  5      | 01101101 | 0010
1250000 | 10  |  5      | 01101101 | 0100
1350000 | 11  |  5      | 01101101 | 1000
1450000 | 11  | 12      | 00000000 | 1000
1550000 | 11  | 15      | 00000000 | 1000




## 4. Consumo de recursos

## 5. Problemas encontrados durante el proyecto
- Ajuste de anchos de bits para evitar overflow

## Apendices:
### Apendice 1:
texto, imágen, etc
