# Integration Tests for PSFFmpeg
# These tests require FFmpeg to be installed and available in PATH
# They also require test media files to be present

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..' 'PSFFmpeg' 'PSFFmpeg.psd1'
    Import-Module $ModulePath -Force

    # Check if FFmpeg is installed
    $script:FFmpegInstalled = $false
    try {
        $null = & ffmpeg -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $script:FFmpegInstalled = $true
        }
    }
    catch {
        Write-Warning "FFmpeg is not installed. Skipping integration tests."
    }

    # Create test output directory
    $script:TestOutputDir = Join-Path $PSScriptRoot 'TestOutput'
    if (Test-Path $script:TestOutputDir) {
        Remove-Item -Path $script:TestOutputDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $script:TestOutputDir -Force | Out-Null

    # Define test assets directory
    $script:TestAssetsDir = Join-Path $PSScriptRoot 'TestAssets'
}

AfterAll {
    # Clean up test output
    if (Test-Path $script:TestOutputDir) {
        Remove-Item -Path $script:TestOutputDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-Module PSFFmpeg -ErrorAction SilentlyContinue
}

Describe 'Integration Tests' -Tag 'Integration' {
    BeforeAll {
        if (-not $script:FFmpegInstalled) {
            Set-ItResult -Skipped -Because "FFmpeg is not installed"
            return
        }
    }

    Context 'Real FFmpeg Operations' {
        BeforeAll {
            # Create a simple test video using FFmpeg
            $script:TestVideo = Join-Path $script:TestAssetsDir 'test_video.mp4'

            if (-not (Test-Path $script:TestAssetsDir)) {
                New-Item -ItemType Directory -Path $script:TestAssetsDir -Force | Out-Null
            }

            # Generate a 5-second test video with color bars and tone
            if (-not (Test-Path $script:TestVideo)) {
                $ffmpegArgs = @(
                    '-f', 'lavfi',
                    '-i', 'testsrc=duration=5:size=1280x720:rate=30',
                    '-f', 'lavfi',
                    '-i', 'sine=frequency=1000:duration=5',
                    '-c:v', 'libx264',
                    '-preset', 'ultrafast',
                    '-c:a', 'aac',
                    '-y',
                    $script:TestVideo
                )

                try {
                    & ffmpeg @ffmpegArgs 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "Failed to create test video"
                        return
                    }
                }
                catch {
                    Write-Warning "Failed to create test video: $_"
                    return
                }
            }

            # Create a test audio file
            $script:TestAudio = Join-Path $script:TestAssetsDir 'test_audio.mp3'
            if (-not (Test-Path $script:TestAudio)) {
                $ffmpegArgs = @(
                    '-f', 'lavfi',
                    '-i', 'sine=frequency=440:duration=3',
                    '-c:a', 'libmp3lame',
                    '-y',
                    $script:TestAudio
                )

                try {
                    & ffmpeg @ffmpegArgs 2>&1 | Out-Null
                }
                catch {
                    Write-Warning "Failed to create test audio: $_"
                }
            }
        }

        It 'Get-MediaInfo should return video information' -Skip:(-not (Test-Path $script:TestVideo)) {
            $info = Get-MediaInfo -Path $script:TestVideo

            $info | Should -Not -BeNullOrEmpty
            $info.HasVideo | Should -Be $true
            $info.VideoWidth | Should -Be 1280
            $info.VideoHeight | Should -Be 720
        }

        It 'Convert-Media should convert video format' -Skip:(-not (Test-Path $script:TestVideo)) {
            $output = Join-Path $script:TestOutputDir 'converted.mp4'

            $result = Convert-Media -InputPath $script:TestVideo -OutputPath $output -VideoCodec h264 -AudioCodec aac -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true

            # Verify output
            $info = Get-MediaInfo -Path $output
            $info.VideoCodec | Should -Be 'h264'
        }

        It 'Resize-Video should change video dimensions' -Skip:(-not (Test-Path $script:TestVideo)) {
            $output = Join-Path $script:TestOutputDir 'resized.mp4'

            $result = Resize-Video -InputPath $script:TestVideo -OutputPath $output -Width 640 -Height 480 -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true

            # Verify output dimensions
            $info = Get-MediaInfo -Path $output
            $info.VideoWidth | Should -Be 640
            $info.VideoHeight | Should -Be 480
        }

        It 'Extract-Audio should extract audio stream' -Skip:(-not (Test-Path $script:TestVideo)) {
            $output = Join-Path $script:TestOutputDir 'audio.mp3'

            $result = Extract-Audio -InputPath $script:TestVideo -OutputPath $output -AudioCodec mp3 -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true

            # Verify output is audio only
            $info = Get-MediaInfo -Path $output
            $info.HasAudio | Should -Be $true
            $info.HasVideo | Should -Be $false
        }

        It 'Edit-Video should trim video' -Skip:(-not (Test-Path $script:TestVideo)) {
            $output = Join-Path $script:TestOutputDir 'trimmed.mp4'

            $result = Edit-Video -InputPath $script:TestVideo -OutputPath $output -StartTime '1' -Duration '2' -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true

            # Verify output duration (approximately 2 seconds, allow some tolerance)
            $info = Get-MediaInfo -Path $output
            $info.DurationSeconds | Should -BeGreaterThan 1.5
            $info.DurationSeconds | Should -BeLessThan 2.5
        }

        It 'New-VideoThumbnail should create thumbnail' -Skip:(-not (Test-Path $script:TestVideo)) {
            $output = Join-Path $script:TestOutputDir 'thumbnail.jpg'

            $result = New-VideoThumbnail -InputPath $script:TestVideo -OutputPath $output -Time '2' -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true
            $result.Extension | Should -Be '.jpg'
        }

        It 'Merge-Video should concatenate videos' -Skip:(-not (Test-Path $script:TestVideo)) {
            # Create a second video for merging
            $video2 = Join-Path $script:TestOutputDir 'test_video2.mp4'

            # Copy the test video as a second video
            Copy-Item -Path $script:TestVideo -Destination $video2

            $output = Join-Path $script:TestOutputDir 'merged.mp4'

            $result = Merge-Video -InputPaths @($script:TestVideo, $video2) -OutputPath $output -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true

            # Verify output duration is approximately double
            $originalInfo = Get-MediaInfo -Path $script:TestVideo
            $mergedInfo = Get-MediaInfo -Path $output
            $mergedInfo.DurationSeconds | Should -BeGreaterThan ($originalInfo.DurationSeconds * 1.8)
        }

        It 'Add-AudioToVideo should replace audio' -Skip:(-not (Test-Path $script:TestVideo) -or -not (Test-Path $script:TestAudio)) {
            $output = Join-Path $script:TestOutputDir 'video_with_audio.mp4'

            $result = Add-AudioToVideo -VideoPath $script:TestVideo -AudioPath $script:TestAudio -OutputPath $output -ReplaceAudio -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $output | Should -Be $true

            # Verify output has both video and audio
            $info = Get-MediaInfo -Path $output
            $info.HasVideo | Should -Be $true
            $info.HasAudio | Should -Be $true
        }
    }
}

Describe 'Integration Test Setup' -Tag 'Setup' {
    It 'Should have FFmpeg installed' {
        $script:FFmpegInstalled | Should -Be $true -Because "Integration tests require FFmpeg"
    }

    It 'Should have test assets directory' {
        Test-Path $script:TestAssetsDir | Should -Be $true
    }

    It 'Should have created test video' {
        if ($script:FFmpegInstalled) {
            Test-Path $script:TestVideo | Should -Be $true
        }
    }
}
