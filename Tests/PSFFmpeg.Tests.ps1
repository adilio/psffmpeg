BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..' 'PSFFmpeg' 'PSFFmpeg.psd1'
    Import-Module $ModulePath -Force

    # Create test directory
    $TestOutputDir = Join-Path $TestDrive 'Output'
    New-Item -ItemType Directory -Path $TestOutputDir -Force | Out-Null

    # Mock FFmpeg installation check
    Mock -ModuleName PSFFmpeg Test-FFmpegInstalled { return $true }
}

AfterAll {
    # Clean up
    Remove-Module PSFFmpeg -ErrorAction SilentlyContinue
}

Describe 'PSFFmpeg Module' {
    Context 'Module Loading' {
        It 'Should import successfully' {
            Get-Module PSFFmpeg | Should -Not -BeNullOrEmpty
        }

        It 'Should export all required functions' {
            $exportedFunctions = (Get-Command -Module PSFFmpeg).Name
            $expectedFunctions = @(
                'Get-MediaInfo',
                'Convert-Media',
                'Resize-Video',
                'Extract-Audio',
                'Edit-Video',
                'Merge-Video',
                'New-VideoThumbnail',
                'Convert-VideoCodec',
                'Add-AudioToVideo'
            )

            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }
    }
}

Describe 'Test-FFmpegInstalled' {
    Context 'FFmpeg Detection' {
        It 'Should detect FFmpeg when installed' {
            Mock -CommandName ffmpeg { return 'ffmpeg version' }
            Mock -CommandName ffprobe { return 'ffprobe version' }

            InModuleScope PSFFmpeg {
                Test-FFmpegInstalled | Should -Be $true
            }
        }

        It 'Should return false when FFmpeg is not installed' {
            Mock -CommandName ffmpeg { throw 'Command not found' }

            InModuleScope PSFFmpeg {
                Test-FFmpegInstalled | Should -Be $false
            }
        }
    }
}

Describe 'Get-MediaInfo' {
    BeforeAll {
        # Create a mock video file
        $script:TestVideoPath = Join-Path $TestDrive 'test.mp4'
        Set-Content -Path $script:TestVideoPath -Value 'dummy video content'

        # Mock ffprobe output
        $mockJson = @{
            format = @{
                filename = $script:TestVideoPath
                format_name = 'mov,mp4,m4a,3gp,3g2,mj2'
                duration = '10.5'
                size = '1048576'
                bit_rate = '100000'
            }
            streams = @(
                @{
                    codec_type = 'video'
                    codec_name = 'h264'
                    codec_long_name = 'H.264 / AVC'
                    width = 1920
                    height = 1080
                    display_aspect_ratio = '16:9'
                    r_frame_rate = '30/1'
                    pix_fmt = 'yuv420p'
                    bit_rate = '80000'
                },
                @{
                    codec_type = 'audio'
                    codec_name = 'aac'
                    codec_long_name = 'AAC (Advanced Audio Coding)'
                    sample_rate = '48000'
                    channels = 2
                    channel_layout = 'stereo'
                    bit_rate = '20000'
                }
            )
        } | ConvertTo-Json -Depth 10

        Mock -ModuleName PSFFmpeg -CommandName ffprobe { return $mockJson }
    }

    Context 'Basic Functionality' {
        It 'Should retrieve media information' {
            $result = Get-MediaInfo -Path $script:TestVideoPath

            $result | Should -Not -BeNullOrEmpty
            $result.Format | Should -Be 'mov,mp4,m4a,3gp,3g2,mj2'
            $result.HasVideo | Should -Be $true
            $result.HasAudio | Should -Be $true
        }

        It 'Should have video properties' {
            $result = Get-MediaInfo -Path $script:TestVideoPath

            $result.VideoCodec | Should -Be 'h264'
            $result.VideoWidth | Should -Be 1920
            $result.VideoHeight | Should -Be 1080
        }

        It 'Should have audio properties' {
            $result = Get-MediaInfo -Path $script:TestVideoPath

            $result.AudioCodec | Should -Be 'aac'
            $result.AudioChannels | Should -Be 2
        }

        It 'Should return JSON when -Json switch is used' {
            $result = Get-MediaInfo -Path $script:TestVideoPath -Json

            $result | Should -BeOfType [string]
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should throw when file does not exist' {
            { Get-MediaInfo -Path 'nonexistent.mp4' } | Should -Throw
        }
    }

    Context 'Pipeline Support' {
        It 'Should accept pipeline input' {
            $fileInfo = Get-Item $script:TestVideoPath
            $result = $fileInfo | Get-MediaInfo

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Convert-Media' {
    BeforeAll {
        $script:TestInputPath = Join-Path $TestDrive 'input.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'output.mp4'
        Set-Content -Path $script:TestInputPath -Value 'dummy video content'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'converted video'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Basic Conversion' {
        It 'Should convert media file' {
            $result = Convert-Media -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Overwrite

            $result | Should -Not -BeNullOrEmpty
            $result.FullName | Should -Be $script:TestOutputPath
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should accept video codec parameter' {
            $result = Convert-Media -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -VideoCodec h264 -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should accept audio codec parameter' {
            $result = Convert-Media -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -AudioCodec aac -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should accept quality presets' {
            foreach ($quality in @('low', 'medium', 'high', 'ultra')) {
                $output = Join-Path $TestOutputDir "output_$quality.mp4"
                $result = Convert-Media -InputPath $script:TestInputPath -OutputPath $output -Quality $quality -Overwrite

                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should handle bitrate parameters' {
            $result = Convert-Media -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath `
                -VideoBitrate '2M' -AudioBitrate '192k' -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Should throw when input file does not exist' {
            { Convert-Media -InputPath 'nonexistent.mp4' -OutputPath $script:TestOutputPath } | Should -Throw
        }

        It 'Should warn when output exists without -Overwrite' {
            Set-Content -Path $script:TestOutputPath -Value 'existing file'

            $result = Convert-Media -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -WarningVariable warnings 3>&1

            $warnings | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Resize-Video' {
    BeforeAll {
        $script:TestInputPath = Join-Path $TestDrive 'input.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'resized.mp4'
        Set-Content -Path $script:TestInputPath -Value 'dummy video content'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'resized video'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Dimension Resizing' {
        It 'Should resize video with dimensions' {
            $result = Resize-Video -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Width 1280 -Height 720 -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should accept aspect ratio preservation' {
            $result = Resize-Video -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Width 1280 -Height -1 -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Preset Scaling' {
        It 'Should resize using presets' {
            foreach ($scale in @('4K', '1080p', '720p', '480p', '360p')) {
                $output = Join-Path $TestOutputDir "resized_$scale.mp4"
                $result = Resize-Video -InputPath $script:TestInputPath -OutputPath $output -Scale $scale -Overwrite

                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Scaling Algorithms' {
        It 'Should accept different scaling algorithms' {
            foreach ($algorithm in @('bilinear', 'bicubic', 'lanczos')) {
                $output = Join-Path $TestOutputDir "resized_$algorithm.mp4"
                $result = Resize-Video -InputPath $script:TestInputPath -OutputPath $output -Width 640 -Height 480 -ScaleAlgorithm $algorithm -Overwrite

                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Extract-Audio' {
    BeforeAll {
        $script:TestInputPath = Join-Path $TestDrive 'input.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'audio.mp3'
        Set-Content -Path $script:TestInputPath -Value 'dummy video content'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'extracted audio'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Audio Extraction' {
        It 'Should extract audio from video' {
            $result = Extract-Audio -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should accept audio codec parameter' {
            $result = Extract-Audio -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -AudioCodec mp3 -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should accept quality presets' {
            foreach ($quality in @('low', 'medium', 'high', 'ultra')) {
                $output = Join-Path $TestOutputDir "audio_$quality.mp3"
                $result = Extract-Audio -InputPath $script:TestInputPath -OutputPath $output -AudioQuality $quality -Overwrite

                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Edit-Video' {
    BeforeAll {
        $script:TestInputPath = Join-Path $TestDrive 'input.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'edited.mp4'
        Set-Content -Path $script:TestInputPath -Value 'dummy video content'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'edited video'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Video Trimming' {
        It 'Should trim video with duration' {
            $result = Edit-Video -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -StartTime '10' -Duration '30' -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should trim video with end time' {
            $result = Edit-Video -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -StartTime '10' -EndTime '40' -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should support fast seek' {
            $result = Edit-Video -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -StartTime '10' -Duration '30' -FastSeek -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Merge-Video' {
    BeforeAll {
        $script:TestInput1 = Join-Path $TestDrive 'input1.mp4'
        $script:TestInput2 = Join-Path $TestDrive 'input2.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'merged.mp4'

        Set-Content -Path $script:TestInput1 -Value 'dummy video 1'
        Set-Content -Path $script:TestInput2 -Value 'dummy video 2'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'merged video'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Video Merging' {
        It 'Should merge multiple videos' {
            $result = Merge-Video -InputPaths @($script:TestInput1, $script:TestInput2) -OutputPath $script:TestOutputPath -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should support re-encoding' {
            $result = Merge-Video -InputPaths @($script:TestInput1, $script:TestInput2) -OutputPath $script:TestOutputPath -ReEncode -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should require at least two files' {
            { Merge-Video -InputPaths @($script:TestInput1) -OutputPath $script:TestOutputPath } | Should -Throw
        }
    }
}

Describe 'New-VideoThumbnail' {
    BeforeAll {
        $script:TestInputPath = Join-Path $TestDrive 'input.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'thumb.jpg'
        Set-Content -Path $script:TestInputPath -Value 'dummy video content'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'thumbnail image'
            $global:LASTEXITCODE = 0
        }

        Mock -ModuleName PSFFmpeg Get-MediaInfo {
            return [PSCustomObject]@{ DurationSeconds = 100 }
        }
    }

    Context 'Thumbnail Generation' {
        It 'Should create thumbnail' {
            $result = New-VideoThumbnail -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should accept time parameter' {
            $result = New-VideoThumbnail -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Time '30' -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should accept dimension parameters' {
            $result = New-VideoThumbnail -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Width 320 -Height 240 -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Convert-VideoCodec' {
    BeforeAll {
        $script:TestInputPath = Join-Path $TestDrive 'input.mp4'
        $script:TestOutputPath = Join-Path $TestOutputDir 'converted.mp4'
        Set-Content -Path $script:TestInputPath -Value 'dummy video content'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'converted video'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Codec Conversion' {
        It 'Should convert video codec' {
            $result = Convert-VideoCodec -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Codec h264 -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should accept CRF parameter' {
            $result = Convert-VideoCodec -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Codec hevc -CRF 20 -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should accept preset parameter' {
            $result = Convert-VideoCodec -InputPath $script:TestInputPath -OutputPath $script:TestOutputPath -Codec h264 -Preset slow -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Add-AudioToVideo' {
    BeforeAll {
        $script:TestVideoPath = Join-Path $TestDrive 'video.mp4'
        $script:TestAudioPath = Join-Path $TestDrive 'audio.mp3'
        $script:TestOutputPath = Join-Path $TestOutputDir 'combined.mp4'

        Set-Content -Path $script:TestVideoPath -Value 'dummy video'
        Set-Content -Path $script:TestAudioPath -Value 'dummy audio'

        Mock -ModuleName PSFFmpeg -CommandName ffmpeg {
            Set-Content -Path $args[-1] -Value 'combined video'
            $global:LASTEXITCODE = 0
        }
    }

    Context 'Audio Addition' {
        It 'Should add audio to video' {
            $result = Add-AudioToVideo -VideoPath $script:TestVideoPath -AudioPath $script:TestAudioPath -OutputPath $script:TestOutputPath -Overwrite

            $result | Should -Not -BeNullOrEmpty
            Test-Path $script:TestOutputPath | Should -Be $true
        }

        It 'Should replace audio when specified' {
            $result = Add-AudioToVideo -VideoPath $script:TestVideoPath -AudioPath $script:TestAudioPath -OutputPath $script:TestOutputPath -ReplaceAudio -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should accept volume parameters' {
            $result = Add-AudioToVideo -VideoPath $script:TestVideoPath -AudioPath $script:TestAudioPath -OutputPath $script:TestOutputPath -AudioVolume 2 -VideoVolume -3 -Overwrite

            $result | Should -Not -BeNullOrEmpty
        }
    }
}
