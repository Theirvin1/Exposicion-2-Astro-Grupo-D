package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.AuthResponse;
import ec.edu.uteq.sgroas.dto.LoginRequest;
import ec.edu.uteq.sgroas.entity.Rol;
import ec.edu.uteq.sgroas.entity.Usuario;
import ec.edu.uteq.sgroas.repository.UsuarioRepository;
import ec.edu.uteq.sgroas.security.JwtService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private TokenService tokenService;

    @InjectMocks
    private AuthService authService;

    @Test
    void loginCorrectoDebeRetornarTokens() {
        Usuario usuario = Usuario.builder()
                .id(1L)
                .nombre("Administrador SGROAS")
                .email("admin@sgroas.com")
                .passwordHash("password-encriptado")
                .rol(Rol.ROLE_ADMIN)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        when(usuarioRepository.findByEmail("admin@sgroas.com"))
                .thenReturn(Optional.of(usuario));
        when(passwordEncoder.matches("123456", "password-encriptado"))
                .thenReturn(true);
        when(jwtService.generarToken(usuario))
                .thenReturn("access-token-prueba");
        when(jwtService.getExpirationMs())
                .thenReturn(3600000L);
        when(tokenService.generarRefreshToken(eq("admin@sgroas.com"), any()))
                .thenReturn("refresh-token-prueba");

        AuthResponse response = authService.login(
                new LoginRequest("admin@sgroas.com", "123456")
        );

        assertNotNull(response);
        assertEquals("access-token-prueba", response.accessToken());
        assertEquals("refresh-token-prueba", response.refreshToken());
        assertEquals("Bearer", response.tokenType());
        assertEquals("ROLE_ADMIN", response.rol());
    }

    @Test
    void loginConPasswordIncorrectoDebeLanzarExcepcion() {
        Usuario usuario = Usuario.builder()
                .id(1L)
                .nombre("Administrador SGROAS")
                .email("admin@sgroas.com")
                .passwordHash("password-encriptado")
                .rol(Rol.ROLE_ADMIN)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        when(usuarioRepository.findByEmail("admin@sgroas.com"))
                .thenReturn(Optional.of(usuario));
        when(passwordEncoder.matches("clave-mal", "password-encriptado"))
                .thenReturn(false);

        assertThrows(
                BadCredentialsException.class,
                () -> authService.login(new LoginRequest("admin@sgroas.com", "clave-mal"))
        );
    }
}