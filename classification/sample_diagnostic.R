# Este script genera un punto dentro de cada polígono de cobertura de la tierra para datos 
# correspondientes a dos semestres del año 
# en la Amazonia Colombiana
###  Instalar paquetes ####
install.packages("sf","stars","leaflet", "gstat", "automap", "raster", "RColorBrewer" )
install.packages("data.table")

###### cargar librerías #######

library(sf)
library(stars)
library(leaflet)
library(gstat)
library(automap)
library(raster)
library(RColorBrewer)
library(sf)      # for working with shapefiles
library(dplyr)   # for data manipulation
library(tidyr)


#Definir rutas de shapefiles con polígonos de cobertura de la tierra y almacenar cada capa en una variable (Una por semestre)
ruta_poli_2022_S1="..//Datos_SIATAC/Coberturas_de_la_Tierra_2022_SI_Escala_1_25000/Coberturas_de_la_Tierra_25K_2022_SI.shp"
ruta_poli_2022_S2="..//Datos_SIATAC/Coberturas_de_la_Tierra_2022_SII_Escala_1_25000/Coberturas_de_la_Tierra_2022_SI_Escala_1_25000.shp"


poli_2022_S1= st_read(ruta_poli_2022_S1)
poli_2022_S2= st_read(ruta_poli_2022_S2)

#Chequear los CRS
crs_poli_2022_S1=st_crs(poli_2022_S1)
crs_poli_2022_S1

crs_poli_2022_S2=st_crs(poli_2022_S2)
crs_poli_2022_S2

#NOmbres de columnas
names(poli_2022_S1)
names(poli_2022_S2)

###### Separar codigo #######
# Convert the "codigo" column to character
poli_2022_S1$codigo <- as.character(poli_2022_S1$codigo)
poli_2022_S2$codigo <- as.character(poli_2022_S2$codigo)

# Use separate to split the "codigo" column into individual digit columns
poli_2022_S1 <- separate(poli_2022_S1, codigo, into = paste0("nivel_", 1:7), sep = 1:7, convert = TRUE)
poli_2022_S2 <- separate(poli_2022_S2, codigo, into = paste0("nivel_", 1:7), sep = 1:7, convert = TRUE)

# Convert the new digit columns to integer type
poli_2022_S1 <- poli_2022_S1 %>%
  mutate(across(starts_with("digit_"), as.integer))
names(poli_2022_S1)


poli_2022_S2 <- poli_2022_S2 %>%
  mutate(across(starts_with("digit_"), as.integer))
names(poli_2022_S2)

print(poli_2022_S1)
print(poli_2022_S2)



#### Truy a faster wa####
###### Contar muestras por nivel1 #######
library(data.table)

# Assuming your data frame is named 'poli_2022_S1'
# Replace 'poli_2022_S1' with the actual name of your data frame if it's different

# Convert 'poli_2022_S1' to a data.table
setDT(poli_2022_S1)
# Calculate the count by 'nivel_1'
count_nivel_1_2022_S1<- poli_2022_S1[, .(count = .N), by = nivel_1][order(-count)]
print(count_nivel_1_2022_S1)

# Calculate the count by 'nivel_1'
setDT(poli_2022_S2)
count_nivel_1_2022_S2<- poli_2022_S2[, .(count = .N), by = nivel_1][order(-count)]
print(count_nivel_1_2022_S2)

num_rows <- nrow(poli_2022_S1)
print(num_rows)
####### Create shapefile de puntos  ######


# Load your shapefile as an sf object
shapefile <- st_read(poli_2022_S1)

# Set the number of random points per polygon
num_points_per_polygon <- 1  # Adjust as needed

# Create a new sf object for random points within polygons
random_points <- shapefile %>%
  group_by(unique_id_column) %>%  # Replace with your unique identifier column name
  slice_sample(n = num_points_per_polygon, replace = FALSE) %>%
  ungroup()

# Write the random points as a new shapefile
st_write(random_points, 'punto_2022_S1.shp')



# para el segundo semeste

# Load your shapefile as an sf object
shapefile <- st_read(poli_2022_S2)

# Set the number of random points per polygon
num_points_per_polygon <- 1  # Adjust as needed

# Create a future plan for parallel processing
plan(multisession)

# Parallelize the point generation using future_lapply
random_points <- future_lapply(1:nrow(shapefile), function(i) {
  random_point <- shapefile[i, ] %>%
    slice_sample(n = num_points_per_polygon, replace = FALSE)
  return(random_point)
})

# Combine the results into an sf object
random_points <- do.call(rbind, random_points)

# Write the random points as a new shapefile
st_write(random_points, 'poli_2022_S2')
