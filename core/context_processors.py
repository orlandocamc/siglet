def carrito_contador(request):
    # Si existe la sesión del carrito, cuenta cuántos elementos tiene
    carrito = request.session.get('carrito', [])
    return {'carrito_count': len(carrito)}

def roles_disponibles(request):
    # Recuperamos la lista de roles de la sesión
    roles = request.session.get('roles_usuario', [])
    
    # Devolvemos banderas (True/False) para usar fácil en el HTML
    return {
        'es_alumno': 'student' in roles,
        'es_profesor': 'professor' in roles,
        'es_tecnico': 'labtech' in roles,
        'es_admin': request.user.is_staff # Por si el admin de Django también quiere jugar
    }