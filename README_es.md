# SynthVisCom

**Conjunto de datos sintéticos para la docencia y la investigación en comunicación visual**

> **Todos los datos de este conjunto son sintéticos.** Se generaron con un
> modelo estadístico documentado y una semilla aleatoria fija. No
> representan a personas reales, diseños reales ni resultados empíricos, y
> no deben citarse como evidencia sobre la percepción humana.

SynthVisCom es un conjunto de datos abierto que simula un estudio en el que
personas observan diseños visuales y responden a ellos. Sirve para plantear
ejercicios con respuesta conocida, practicar todo el ciclo de análisis sin
riesgos de privacidad y probar métodos con datos cuyos efectos generadores
se conocen.

| Tabla | Filas | Cada fila es |
|---|---|---|
| `data/synthetic_designs.csv` | 2.000 | un cartel, infografía, gráfico de datos, imagen para redes sociales o diapositiva ficticios, descritos por paleta, armonía y saturación del color, contraste WCAG, tipografía, maquetación, alineación, espacio en blanco, jerarquía, proporción imagen/texto, número de palabras, rostros, tipo de gráfico, ratio datos-tinta y texto alternativo |
| `data/synthetic_participants.csv` | 1.000 | un participante ficticio: grupo de edad, experiencia en diseño, alfabetización visual, visión del color, baja visión y dispositivo |
| `data/synthetic_responses.csv` | 20.000 | la respuesta de un participante a un diseño (20 cada uno): tiempo hasta la primera fijación, tiempo de visualización, comprensión (0-5), valoraciones estética y de preferencia (1-7), carga cognitiva (0-100), recuerdo a las 24 horas e interacción |
| `images/` | 2.000 PNG | una imagen por diseño, dibujada a partir de sus variables: paleta, contraste WCAG exacto del texto, tipografías y tamaños, maquetación, espacio en blanco, jerarquía, proporción de imagen, rostros esquemáticos, gráficos y adornos superfluos (*chart junk*) |

- **Libro de códigos:** `metadata/codebook.csv` documenta cada variable; `metadata/images.csv` describe cada imagen (colores, contraste dibujado, paleta).
- **Verdad conocida:** `metadata/true_effects.csv` recoge todos los efectos
  del modelo, por ejemplo la fuerte caída de la comprensión por debajo de un
  contraste de 4,5:1, mayor en participantes con daltonismo o baja visión.
- **Descriptor de datos:** [`DATA_DESCRIPTOR.md`](DATA_DESCRIPTOR.md) explica
  cómo se simuló cada variable y qué no pueden mostrar los datos.

Los ficheros son CSV en UTF-8 y se abren con cualquier herramienta. En
`examples/` hay un script de introducción y un cuaderno con nueve ejercicios
resueltos (en inglés), incluido uno de crítica de las imágenes. `code/generator.R` contiene el modelo completo en R
base para generar estudios sintéticos nuevos de cualquier tamaño.

## Reproducibilidad

```sh
Rscript code/build.R   # regenera data/, images/, metadata/ y MD5SUMS (unos minutos)
Rscript code/check.R   # comprobaciones de integridad, coherencia e imágenes
```

## Cómo citar

Sánchez-Núñez, P. (2026). *Synthetic Dataset for Visual Communication
Education and Research* (SynthVisCom, versión 0.1.0) [Conjunto de datos].
https://github.com/pablosancheznunez/synthviscom

## Licencias

- Datos, imágenes, libro de códigos, descriptor, ejemplos y documentación:
  [CC BY 4.0](LICENSE-DATA.md).
- Código de `code/`: [MIT](LICENSE).

## Autor

Pablo Sánchez-Núñez · [ORCID 0000-0001-7845-9506](https://orcid.org/0000-0001-7845-9506)
· <https://pablosancheznunez.com>
