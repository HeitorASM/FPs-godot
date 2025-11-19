# Adicione este script ao MuzzleFlash ou configure manualmente:

# 1. Crie um Material simples:
# - Albedo Color: Laranja/Amarelo (#FF8C00)
# - Emission: Mesma cor com intensidade 2.0
# - Flags → Transparent: On
# - Blend Mode: Add

# 2. Ou use StandardMaterial3D via código:
extends MeshInstance3D

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.55, 0.0)  # Laranja
	material.emission_enabled = true
	material.emission = Color(1.0, 0.55, 0.0)
	material.emission_energy = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	set_surface_override_material(0, material)
