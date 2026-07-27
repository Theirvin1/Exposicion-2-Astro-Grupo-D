package ec.edu.uteq.sgroas.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record ConductorRequest(

        @NotBlank(message = "Los nombres son obligatorios")
        @Size(max = 100, message = "Los nombres no pueden superar los 100 caracteres")
        String nombres,

        @NotBlank(message = "Los apellidos son obligatorios")
        @Size(max = 100, message = "Los apellidos no pueden superar los 100 caracteres")
        String apellidos,

        @NotBlank(message = "La cedula es obligatoria")
        @Pattern(regexp = "\\d{10}", message = "La cedula debe tener 10 digitos")
        String cedula,

        @NotBlank(message = "El numero de licencia es obligatorio")
        @Size(max = 30, message = "El numero de licencia no puede superar los 30 caracteres")
        String numeroLicencia,

        @NotBlank(message = "El tipo de licencia es obligatorio")
        @Size(max = 10, message = "El tipo de licencia no puede superar los 10 caracteres")
        String tipoLicencia,

        @NotNull(message = "La fecha de vencimiento de la licencia es obligatoria")
        LocalDate fechaVencimientoLicencia,

        @Size(max = 20, message = "El telefono no puede superar los 20 caracteres")
        String telefono,

        @Email(message = "El email debe tener un formato valido")
        @Size(max = 255, message = "El email no puede superar los 255 caracteres")
        String email,

        @NotBlank(message = "El estado es obligatorio")
        String estado
) {
}