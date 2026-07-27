package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.AuthResponse;
import ec.edu.uteq.sgroas.dto.LoginRequest;
import ec.edu.uteq.sgroas.dto.RefreshTokenRequest;
import ec.edu.uteq.sgroas.dto.RegisterRequest;
import ec.edu.uteq.sgroas.entity.Rol;
import ec.edu.uteq.sgroas.entity.Usuario;
import ec.edu.uteq.sgroas.repository.UsuarioRepository;
import ec.edu.uteq.sgroas.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TokenService tokenService;

    @Value("${app.jwt.refresh-expiration-ms}")
    private Long refreshExpirationMs;

    public AuthResponse registrar(RegisterRequest request) {
        if (usuarioRepository.existsByEmail(request.email())) {
            throw new IllegalArgumentException("Ya existe un usuario con ese email");
        }

        Usuario usuario = Usuario.builder()
                .nombre(request.nombre())
                .email(request.email())
                .passwordHash(passwordEncoder.encode(request.password()))
                .rol(convertirRol(request.rol()))
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        Usuario usuarioGuardado = usuarioRepository.save(usuario);

        return generarRespuestaAutenticacion(usuarioGuardado);
    }

    public AuthResponse login(LoginRequest request) {
        Usuario usuario = usuarioRepository.findByEmail(request.email())
                .filter(Usuario::getActivo)
                .orElseThrow(() -> new BadCredentialsException("Credenciales invalidas"));

        if (!passwordEncoder.matches(request.password(), usuario.getPasswordHash())) {
            throw new BadCredentialsException("Credenciales invalidas");
        }

        return generarRespuestaAutenticacion(usuario);
    }

    public AuthResponse refresh(RefreshTokenRequest request) {
        String email = tokenService.obtenerEmailDesdeRefreshToken(request.refreshToken());

        Usuario usuario = usuarioRepository.findByEmail(email)
                .filter(Usuario::getActivo)
                .orElseThrow(() -> new BadCredentialsException("Usuario no valido"));

        tokenService.eliminarRefreshToken(request.refreshToken());

        return generarRespuestaAutenticacion(usuario);
    }

    public void logout(String accessToken, RefreshTokenRequest request) {
        tokenService.agregarAccessTokenABlacklist(accessToken);
        tokenService.eliminarRefreshToken(request.refreshToken());
    }

    private AuthResponse generarRespuestaAutenticacion(Usuario usuario) {
        String accessToken = jwtService.generarToken(usuario);
        String refreshToken = tokenService.generarRefreshToken(
                usuario.getEmail(),
                refreshExpirationMs
        );

        return new AuthResponse(
                accessToken,
                refreshToken,
                "Bearer",
                jwtService.getExpirationMs(),
                usuario.getNombre(),
                usuario.getEmail(),
                usuario.getRol().name()
        );
    }

    private Rol convertirRol(String rol) {
        try {
            return Rol.valueOf(rol.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Rol no valido");
        }
    }
}