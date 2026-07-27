package ec.edu.uteq.sgroas.dto;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        Long expiresIn,
        String nombre,
        String email,
        String rol
) {
}