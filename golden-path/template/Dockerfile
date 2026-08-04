# =============================================================================
# Golden Path Dockerfile Template
# Dev sửa: EXPOSE port, build command
# =============================================================================
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
