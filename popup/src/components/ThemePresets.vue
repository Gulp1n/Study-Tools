<script setup>
import { ref, computed, inject } from 'vue'
import { useFileDialog } from '@vueuse/core'
import { presets, propertyKeys } from '../../public/themePresets.js'

const syncedStorage = inject('syncedStorage')
const localStorage = inject('localStorage')

const promptOpen = ref(false)
const deletionPrompt = ref(false)
const promptingPreset = ref({})
const promptingIndex = ref(0)

const storedThemes = computed({
    get() {
        return Object.values(localStorage.value?.storedThemes || [])
    },
    set(value) {
        localStorage.value.storedThemes = value
    }
})

const allPresets = computed(() => [...storedThemes.value, ...presets])

const { open: openFileDialog, onChange } = useFileDialog({
    multiple: false, accept: '.sttheme', reset: true,
})
onChange(async (files) => { if (files?.[0]) presetUploaded(files[0]) })

document.addEventListener('dragover', (e) => e.preventDefault())
document.addEventListener('drop', (e) => {
    e.preventDefault()
    presetUploaded(e.dataTransfer.files[0])
})

async function presetUploaded(file) {
    if (storedThemes.value.length >= 9) return

    const json = JSON.parse(await file.text())
    const fallbackPreset = presets[0]

    let obj = {};
    ([...propertyKeys, 'name', 'author', 'date']).forEach(key => {
        if (json?.[key] !== fallbackPreset[key]) obj[key] = json[key]
    })

    if (allPresets.value.some(p => presetsMatch(p, obj))) return

    storedThemes.value = [
        ...storedThemes.value,
        {
            date: new Date().toISOString(),
            ...obj
        }
    ]
}

function applyPreset() {
    const preset = promptingPreset.value
    const fallbackPreset = presets[0]

    propertyKeys.forEach(key => syncedStorage.value[key] = (preset?.[key] ?? fallbackPreset[key]))
}

function presetsMatch(preset1, preset2 = syncedStorage.value) {
    const fallbackPreset = presets[0]

    // Return true if every property matches the preset (or, if it doesn't exist, the fallback preset)
    return propertyKeys.every(key => (preset2?.[key] ?? fallbackPreset[key]) === (preset1?.[key] ?? fallbackPreset[key]))
}

function promptPreset(preset) {
    promptingPreset.value = preset
    if (allPresets.value.some(p => presetsMatch(p))) applyPreset()
    else promptOpen.value = true
}

function generatePresetUrl(preset) {
    const fallbackPreset = presets[0]

    let obj = {};
    ([...propertyKeys, 'name', 'author', 'date']).forEach(key => {
        if (preset?.[key] !== fallbackPreset[key]) obj[key] = preset[key]
    })

    return "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(obj))
}
</script>

<template>
    <div id="theme-presets">
        <div id="personal-presets" class="theme-presets-grid" v-if="storedThemes.length > 0">
            <TransitionGroup name="presets">
                <button v-for="(preset, i) in storedThemes" :key="preset.name || preset.date" class="theme-preset"
                    :class="{ matches: presetsMatch(preset) }"
                    :title="'Persoonlijk thema\n' + (preset.name || new Date(preset.date)?.toLocaleString('nl-NL')) + '\nKlik om toe te passen'"
                    @click="promptPreset(preset)">
                    <MagisterThemePreview class="theme-preset-preview" :preset="preset" :scale="1.1" />
                    <div class="theme-actions">
                        <button class="theme-preset-remove" @click.stop="promptingIndex = i; deletionPrompt = true"
                            title="Persoonlijk thema verwijderen">
                            <Icon>delete</Icon>
                        </button>
                        <a class="theme-preset-download" @click.stop title="Persoonlijk thema exporteren naar bestand"
                            :href="generatePresetUrl(preset)" :download="preset.date + '.sttheme'">
                            <Icon>file_export</Icon>
                        </a>
                    </div>
                </button>
                <div key="add-new" class="personal-presets-actions" v-if="storedThemes.length < 9">
                    <!-- <button class="theme-preset-upload" title="Thema's toevoegen vanuit themawinkel">
                    <Icon>storefront</Icon>
                </button> -->
                    <button class="theme-preset-upload" title="Persoonlijk thema importeren vanuit bestand"
                        @click="openFileDialog">
                        <Icon>add</Icon>
                    </button>
                </div>
            </TransitionGroup>
        </div>
        <div id="public-presets" class="theme-presets-grid">
            <button v-for="(preset, i) in presets" class="theme-preset" :class="{ matches: presetsMatch(preset) }"
                :title="preset.name" @click="promptPreset(preset)">
                <MagisterThemePreview class="theme-preset-preview" :preset="preset" />
                <div class="theme-preset-info">
                    <span class="theme-preset-name">{{ preset.name }}</span>
                    <span v-if="i >= 6" class="theme-preset-author">{{ preset.author }}</span>
                </div>
            </button>
        </div>

        <Dialog v-model:active="promptOpen">
            <template #icon>format_paint</template>
            <template #headline>Let op!</template>
            <template #text>
                Je hebt wijzigingen aangebracht aan je thema. Als je dit thema nu toepast, dan gaan je huidige thema en
                al je
                aangepaste themavoorkeuren verloren.
            </template>
            <template #buttons>
                <button @click="applyPreset(); promptOpen = false">Toepassen</button>
                <button @click="promptOpen = false">Annuleren</button>
            </template>
        </Dialog>

        <Dialog v-model:active="deletionPrompt">
            <template #icon>delete</template>
            <template #headline>Thema verwijderen?</template>
            <template #text>
                Deze actie kan niet ongedaan worden gemaakt.
            </template>
            <template #buttons>
                <button
                    @click="storedThemes = storedThemes.filter((v, i) => i !== promptingIndex); deletionPrompt = false">Verwijderen</button>
                <button @click="deletionPrompt = false">Annuleren</button>
            </template>
        </Dialog>
    </div>
</template>

<style scoped>
.theme-presets-grid {
    position: relative;
    display: grid;
    grid-template-columns: 50% 50%;
    justify-items: stretch;
    gap: 8px;
    margin: 8px;
    margin-bottom: 16px;
}

#personal-presets {
    grid-template-columns: repeat(3, calc(100% / 3));
    background-color: var(--color-surface);
    outline: 1px solid var(--color-outline-variant);
    border-radius: 12px;
    padding: 8px;
}

.theme-preset {
    position: relative;
    display: flex;
    flex-direction: column;
    gap: 6px;
    padding: 0;
    margin: 0;
    padding: 8px;
    background-color: var(--color-surface-container);
    border: none;
    border-radius: 12px;
    cursor: pointer;
}

#public-presets .theme-preset.matches {
    background-color: var(--color-primary-container);
    outline: 1px solid var(--color-outline);
}

#personal-presets .theme-preset {
    padding: 0;
    overflow: hidden;
    padding: 1px;
    border-radius: 8px;
    background-color: transparent;
}

#personal-presets .theme-preset .theme-preset-preview {
    height: 70px;
}

.theme-preset-preview {
    grid-area: preview;
    width: 100%;
    height: 90px;
    border-radius: 8px;
    outline: 1px solid var(--color-outline-variant);
    overflow: hidden;
}

.theme-preset.matches .theme-preset-preview {
    outline: 1px solid var(--color-outline);
}

.theme-preset-info {
    display: flex;
    flex-direction: column;
    align-items: start;
}

.theme-preset-name {
    font: var(--typescale-body-medium);
    color: var(--color-on-surface-container);
}

.theme-preset-author,
.theme-preset-date {
    font: var(--typescale-body-small);
    color: var(--color-on-surface-variant);
}

.theme-actions {
    display: flex;
    position: absolute;
    bottom: 1px;
    left: 1px;
    right: 1px;
    justify-content: center;
    padding-inline: 4px;
    pointer-events: none;
    opacity: 0;
    scale: 1 0.75;
    translate: 0 50%;
    background-color: hsl(from var(--color-surface-variant) h s l / 0.75);
    border-top: 1px solid var(--color-outline-variant);
    border-bottom-left-radius: 8px;
    border-bottom-right-radius: 8px;
    transition: opacity 100ms, scale 100ms, translate 100ms;
}

.theme-preset:hover .theme-actions,
.theme-preset:focus-within .theme-actions,
.theme-preset.matches .theme-actions {
    opacity: 1;
    scale: 1;
    translate: 0;
    pointer-events: all;
}

.theme-actions>*,
.personal-presets-actions>* {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 34px;
    height: 34px;
    border-radius: 50%;
    border: none;
    background-color: transparent;
    color: var(--color-on-surface-variant);
    cursor: pointer;
    text-decoration: none;
    transition: background-color 100ms;
}

.theme-actions>* {
    width: 34px;
    height: 34px;
    color: var(--color-on-surface);
}

.theme-actions>*:hover,
.personal-presets-actions>*:hover {
    background-color: #12212114;
}

.theme-actions>*>.icon {
    font-size: 22px;
}

.personal-presets-actions {
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: var(--color-surface-container);
    border-radius: 8px;
    padding: 4px;
}

.personal-presets-actions.highlight {
    background-color: var(--color-surface-variant);
}

.personal-presets-actions:nth-child(3n-2) {
    grid-column: span 3;
}

/* .personal-presets-actions:nth-child(3n-1) {
    grid-column: span 2;
} */

.personal-presets-actions>* {
    flex-grow: 2;
    height: 100%;
    border-radius: 8px;
}

.presets-move,
.presets-enter-active,
.presets-leave-active {
    transition: all 300ms ease;
}

.presets-enter-active {
    transition-delay: 100ms;
    transition-duration: 500ms;
}

.presets-enter-from {
    opacity: 0;
    scale: 1.5;
}

.presets-leave-to {
    opacity: 0;
    scale: 0.75;
}

.presets-leave-active {
    position: absolute;
}
</style>