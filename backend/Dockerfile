# syntax=docker/dockerfile:1

FROM eclipse-temurin:25-jdk AS build
WORKDIR /app

# Avoid apt mirrors (flaky on some Temurin base images); install Maven from Apache.
ARG MAVEN_VERSION=3.9.11
RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    | tar -xz -C /opt \
    && ln -s "/opt/apache-maven-${MAVEN_VERSION}/bin/mvn" /usr/local/bin/mvn

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
