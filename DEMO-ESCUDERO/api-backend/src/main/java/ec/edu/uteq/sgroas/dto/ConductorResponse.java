package ec.edu.uteq.sgroas.dto;

import java.time.Instant;
import java.time.LocalDate;

public record ConductorResponse(
        Long id,
        String nombres,
        String apellidos,
        String cedula,
        String numeroLicencia,
        String tipoLicencia,
        LocalDate fechaVencimientoLicencia,
        String telefono,
        String email,
        String estado,
        Boolean activo,
        Boolean licenciaPorVencer,
        Instant creadoEn,
        Instant actualizadoEn
) {
}