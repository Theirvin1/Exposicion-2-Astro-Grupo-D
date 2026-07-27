package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class TokenService {

    private final JwtService jwtService;
    private final Map<String, String> refreshTokens = new ConcurrentHashMap<>();
    private final Map<String, Long> blacklist = new ConcurrentHashMap<>();

    public String generarRefreshToken(String email, Long refreshExpirationMs) {
        String refreshToken = UUID.randomUUID().toString();
        refreshTokens.put(refreshToken, email);
        return refreshToken;
    }

    public String obtenerEmailDesdeRefreshToken(String refreshToken) {
        String email = refreshTokens.get(refreshToken);
        if (email == null) {
            throw new IllegalArgumentException("Refresh token no valido o expirado");
        }
        return email;
    }

    public void eliminarRefreshToken(String refreshToken) {
        refreshTokens.remove(refreshToken);
    }

    public void agregarAccessTokenABlacklist(String accessToken) {
        String jti = jwtService.extraerJti(accessToken);
        long tiempoRestante = jwtService.extraerExpiracion(accessToken).getTime()
                - System.currentTimeMillis();
        if (tiempoRestante > 0) {
            blacklist.put(jti, System.currentTimeMillis() + tiempoRestante);
        }
    }

    public boolean accessTokenEnBlacklist(String accessToken) {
        String jti = jwtService.extraerJti(accessToken);
        Long expira = blacklist.get(jti);
        if (expira == null) return false;
        if (System.currentTimeMillis() > expira) {
            blacklist.remove(jti);
            return false;
        }
        return true;
    }
}
