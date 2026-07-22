# syntax=docker/dockerfile:1

FROM eclipse-temurin:25-jdk AS build
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends maven \
    && rm -rf /var/lib/apt/lists/*

COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:25-jre
WORKDIR /app

RUN useradd --system --create-home --uid 10001 lokal \
    && mkdir -p /tmp/lokal-uploads \
    && chown -R lokal:lokal /app /tmp/lokal-uploads

COPY --from=build /app/target/lokal-api-*.jar /app/app.jar
USER lokal

ENV SPRING_PROFILES_ACTIVE=prod
ENV UPLOAD_PATH=/tmp/lokal-uploads
ENV PORT=8080

EXPOSE 8080
ENTRYPOINT ["java","-XX:+UseContainerSupport","-XX:MaxRAMPercentage=75.0","-jar","/app/app.jar"]
