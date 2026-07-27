# ==================================================
# DEMO-SGB - Dockerfile del backend (autocontenido)
# ==================================================
# A diferencia del Dockerfile original del repo (que necesita
# build.context = raiz del repo para copiar database/migrations/ desde
# fuera de backend-springboot/), esta version de la demo es autocontenida:
# database/migrations/ vive DENTRO de esta misma carpeta
# (backend-springboot/database/migrations/), asi que el build context
# puede ser "./backend-springboot" tal cual, igual que en DEMO-MARISCAL.

FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

COPY mvnw mvnw.cmd ./
COPY .mvn/ .mvn/
COPY pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

COPY src/ src/
RUN ./mvnw clean package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=build /app/target/backend-0.0.1-SNAPSHOT.jar app.jar
COPY database/migrations database/migrations

EXPOSE 8080

RUN apk add --no-cache curl

ENTRYPOINT ["java", "-jar", "app.jar"]
